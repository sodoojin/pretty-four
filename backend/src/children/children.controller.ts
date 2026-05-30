import { Controller, Get, Post, Patch, Body, Param, UseGuards, Request } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ChildrenService } from './children.service';
import { CreateChildDto } from './dto/create-child.dto';

@UseGuards(JwtAuthGuard)
@Controller('children')
export class ChildrenController {
  constructor(private readonly service: ChildrenService) {}

  @Get('current')
  getCurrent(@Request() req) {
    return this.service.findCurrent(req.user.id);
  }

  @Post()
  create(@Request() req, @Body() dto: CreateChildDto) {
    return this.service.create(req.user.id, dto);
  }

  @Patch(':id')
  update(@Request() req, @Param('id') id: string, @Body() dto: CreateChildDto) {
    return this.service.update(id, req.user.id, dto);
  }
}
