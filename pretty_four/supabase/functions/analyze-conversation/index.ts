import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Anthropic from 'https://esm.sh/@anthropic-ai/sdk@0.24.3'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

Deno.serve(async (req) => {
  try {
    const { session_id } = await req.json()

    // 1. 세션 + 아이 정보 조회
    const { data: session, error: sessionErr } = await supabase
      .from('sessions')
      .select('*, children(birth_date, user_id)')
      .eq('id', session_id)
      .single()
    if (sessionErr) throw sessionErr

    // 2. Storage에서 오디오 다운로드
    const userId = session.children.user_id
    const { data: audioData, error: storageErr } = await supabase.storage
      .from('recordings')
      .download(`${userId}/${session_id}.m4a`)
    if (storageErr) throw storageErr

    // 3. Whisper STT
    const formData = new FormData()
    formData.append('file', new File([audioData], 'audio.m4a', { type: 'audio/m4a' }))
    formData.append('model', 'whisper-1')
    formData.append('response_format', 'verbose_json')
    formData.append('timestamp_granularities[]', 'segment')

    const whisperRes = await fetch('https://api.openai.com/v1/audio/transcriptions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${Deno.env.get('OPENAI_API_KEY')}` },
      body: formData,
    })
    if (!whisperRes.ok) throw new Error(`Whisper error: ${await whisperRes.text()}`)
    const whisperData = await whisperRes.json()

    const transcript = whisperData.segments
      .map((s: { start: number; text: string }) => `${Math.floor(s.start)}초: ${s.text.trim()}`)
      .join('\n')

    // 4. 연령 계산
    const birthDate = new Date(session.children.birth_date)
    const now = new Date()
    const ageMonths =
      (now.getFullYear() - birthDate.getFullYear()) * 12 +
      (now.getMonth() - birthDate.getMonth())

    // 5. Claude 분석
    const anthropic = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY') })

    const claudeRes = await anthropic.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 4096,
      messages: [
        {
          role: 'user',
          content: `당신은 아동 발달 전문가이자 육아 코칭 전문가입니다.

아이 나이: 만 ${Math.floor(ageMonths / 12)}세 ${ageMonths % 12}개월 (총 ${ageMonths}개월)
발달 단계 지침: ${getCoachingContext(ageMonths)}

아래는 부모와 아이의 대화 전사 내용입니다:
---
${transcript}
---

다음 JSON 형식으로만 응답하세요 (설명 없이 JSON만):
{
  "summary": {
    "tone": "전반적인 대화 분위기 한 단어 (예: 지시적, 협력적, 갈등적)",
    "patterns": ["발견된 패턴1", "발견된 패턴2"],
    "improvements": ["개선 제안1", "개선 제안2"]
  },
  "feedbacks": [
    {
      "timestamp_sec": 타임스탬프_정수,
      "original": "실제 발화 내용",
      "suggestion": "더 효과적인 대안 표현",
      "reason": "이렇게 말하면 좋은 이유 (1~2문장)"
    }
  ]
}`,
        },
      ],
    })

    // Claude 응답 검증
    if (!claudeRes.content.length || claudeRes.content[0].type !== 'text') {
      throw new Error('Claude returned non-text response')
    }

    // markdown 코드 펜스 제거
    const rawText = claudeRes.content[0].text
      .replace(/^```json\s*/m, '')
      .replace(/^```\s*/m, '')
      .replace(/```\s*$/m, '')
      .trim()

    let analysis: { summary: unknown; feedbacks: unknown[] }
    try {
      analysis = JSON.parse(rawText)
    } catch (parseErr) {
      throw new Error(`Claude response is not valid JSON: ${rawText.slice(0, 200)}`)
    }

    // 필수 필드 검증
    if (!analysis.summary || typeof analysis.summary !== 'object') {
      throw new Error('Claude response missing summary field')
    }
    if (!Array.isArray(analysis.feedbacks)) {
      throw new Error('Claude response missing feedbacks array')
    }

    // 6. DB 저장
    const { error: insertErr } = await supabase.from('analysis_results').insert({
      session_id,
      summary: analysis.summary,
      feedbacks: analysis.feedbacks,
      raw_transcript: transcript,
      child_age_months: ageMonths,
    })
    if (insertErr) throw insertErr

    // 7. 세션 상태 업데이트
    await supabase.from('sessions').update({ status: 'completed' }).eq('id', session_id)

    // 8. 오디오 파일 삭제
    await supabase.storage.from('recordings').remove([`${userId}/${session_id}.m4a`])

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error(err)
    const errorMessage = err instanceof Error ? err.message : String(err)
    const body = await req.clone().json().catch(() => ({}))
    if (body.session_id) {
      await supabase
        .from('sessions')
        .update({ status: 'failed' })
        .eq('id', body.session_id)
        .catch(() => {})
    }
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})

function getCoachingContext(ageMonths: number): string {
  if (ageMonths < 48)
    return '단순하고 일관된 지시, 짧은 문장, 즉각적 피드백을 강조하세요.'
  if (ageMonths < 84)
    return '선택지 제공과 규칙의 이유 설명을 강조하세요.'
  if (ageMonths < 132)
    return '논리적 설명과 감정 공감을 강조하세요.'
  return '협상과 타협을 통한 자율성 존중을 강조하세요.'
}
