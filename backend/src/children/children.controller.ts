import {
  Controller, Get, Post, Put, Patch, Delete, Body, Param, HttpCode, UseGuards, Request,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ChildrenService } from './children.service';
import { CreateChildDto } from './dto/create-child.dto';
import { SetActiveChildDto } from './dto/set-active-child.dto';

@UseGuards(JwtAuthGuard)
@Controller('children')
export class ChildrenController {
  constructor(private readonly service: ChildrenService) {}

  @Get()
  list(@Request() req) {
    return this.service.findAll(req.user.id);
  }

  @Get('active')
  getActive(@Request() req) {
    return this.service.getActive(req.user.id);
  }

  @Put('active')
  @HttpCode(200)
  setActive(@Request() req, @Body() dto: SetActiveChildDto) {
    return this.service.setActive(req.user.id, dto.childId);
  }

  // 하위호환: 기존 클라이언트용. 신규 코드는 /children/active 사용.
  @Get('current')
  getCurrent(@Request() req) {
    return this.service.getActive(req.user.id);
  }

  @Post()
  create(@Request() req, @Body() dto: CreateChildDto) {
    return this.service.create(req.user.id, dto);
  }

  @Patch(':id')
  update(@Request() req, @Param('id') id: string, @Body() dto: CreateChildDto) {
    return this.service.update(id, req.user.id, dto);
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@Request() req, @Param('id') id: string) {
    await this.service.remove(id, req.user.id);
  }
}
