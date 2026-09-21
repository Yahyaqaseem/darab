import { Controller, Get, Post, Body, Param, Query, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery, ApiBearerAuth } from '@nestjs/swagger';
import { RoadCallService } from './road-call.service';
import { AskRoadQuestionDto, AnswerRoadQuestionDto } from './dto/road-call.dto';
import { AuthGuard } from '@nestjs/passport';

@ApiTags('نداء الطريق (Road Call System)')
@Controller('road-call')
export class RoadCallController {
  constructor(private readonly roadCallService: RoadCallService) {}

  @Post('ask')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'إطلاق نداء طريق موجه للسائقين أمام المستخدم' })
  async askQuestion(@Req() req: any, @Body() dto: AskRoadQuestionDto) {
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000001';
    return this.roadCallService.askQuestion(userId, dto);
  }

  @Get('active')
  @ApiOperation({ summary: 'جلب نداءات الطريق النشطة الموجهة للسائق في موقعه الحالي' })
  @ApiQuery({ name: 'lat', required: true, type: Number, example: 36.191113 })
  @ApiQuery({ name: 'lng', required: true, type: Number, example: 44.009167 })
  @ApiQuery({ name: 'bearing', required: false, type: Number, example: 315 })
  async getActiveQuestions(
    @Query('lat') lat: number,
    @Query('lng') lng: number,
    @Query('bearing') bearing?: number,
  ) {
    return this.roadCallService.getActiveQuestionsForDriver(
      Number(lat),
      Number(lng),
      bearing !== undefined ? Number(bearing) : undefined,
    );
  }

  @Post(':id/answer')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'الإجابة السريعة بزر واحد على نداء طريق' })
  async answerQuestion(
    @Param('id') id: string,
    @Req() req: any,
    @Body() dto: AnswerRoadQuestionDto,
  ) {
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000001';
    return this.roadCallService.answerQuestion(id, userId, dto);
  }
}
