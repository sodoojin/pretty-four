import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

Deno.serve(async (req) => {
  try {
    const { kakao_access_token } = await req.json()

    // 카카오 사용자 정보 조회
    const userRes = await fetch('https://kapi.kakao.com/v2/user/me', {
      headers: { Authorization: `Bearer ${kakao_access_token}` },
    })
    if (!userRes.ok) {
      return new Response(JSON.stringify({ error: 'Invalid Kakao token' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }
    const kakaoUser = await userRes.json()
    const email = kakaoUser.kakao_account?.email

    if (!email) {
      return new Response(
        JSON.stringify({ error: '카카오 이메일 동의가 필요합니다.' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      )
    }

    // Supabase 사용자 생성 (이미 있으면 무시)
    const { error: createErr } = await supabase.auth.admin.createUser({
      email,
      email_confirm: true,
      user_metadata: { provider: 'kakao' },
    })
    if (createErr && !createErr.message.toLowerCase().includes('already')) {
      throw createErr
    }

    // Magic link 토큰 생성
    const { data: link, error: linkErr } = await supabase.auth.admin.generateLink({
      type: 'magiclink',
      email,
    })
    if (linkErr) throw linkErr

    return new Response(
      JSON.stringify({ access_token: link.properties?.hashed_token }),
      { headers: { 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    console.error(err)
    const msg = err instanceof Error ? err.message : String(err)
    return new Response(JSON.stringify({ error: msg }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
