import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { ReportsService } from '../reports/reports.service';
import { AskRoadQuestionDto, AnswerRoadQuestionDto, RoadQuestionType } from './dto/road-call.dto';
import { ReportType } from '../reports/dto/reports.dto';
import { v4 as uuidv4 } from 'uuid';
import { GeoUtils } from '../../common/utils/geo.utils';

@Injectable()
export class RoadCallService {
  private readonly logger = new Logger(RoadCallService.name);
  private memoryQuestions = new Map<string, any>();

  constructor(
    private readonly db: DatabaseService,
    private readonly realtimeGateway: RealtimeGateway,
    private readonly reportsService: ReportsService,
  ) {
    this.seedInitialQuestions();
  }

  private seedInitialQuestions() {
    const q1 = {
      id: 'nidaa-1',
      requesterUserId: '00000000-0000-0000-0000-000000000002',
      questionType: RoadQuestionType.TRAFFIC,
      title: 'هل هنالك زحمة؟',
      customText: null,
      latitude: 36.2300,
      longitude: 43.8500,
      bearing: 310,
      targetRadiusMeters: 15000,
      roadName: 'طريق أربيل - دهوك M10',
      answersYes: 8,
      answersNo: 1,
      answersNotSure: 1,
      totalAnswers: 10,
      isAggregated: true,
      aggregatedSummary: '🔴 زحمة محتملة أمامك (8 من 10 سواق أكدوا وجودها)',
      expiresAt: new Date(Date.now() + 15 * 60 * 1000),
      createdAt: new Date(Date.now() - 3 * 60 * 1000),
    };

    const q2 = {
      id: 'nidaa-2',
      requesterUserId: '00000000-0000-0000-0000-000000000003',
      questionType: RoadQuestionType.CHECKPOINT,
      title: 'هل توجد سيطرة / تفتيش؟',
      customText: null,
      latitude: 33.3500,
      longitude: 44.4000,
      bearing: 0,
      targetRadiusMeters: 20000,
      roadName: 'طريق بغداد - سامراء',
      answersYes: 5,
      answersNo: 0,
      answersNotSure: 0,
      totalAnswers: 5,
      isAggregated: true,
      aggregatedSummary: '👮 سيطرة نشطة ومؤكدة من 5 سواق',
      expiresAt: new Date(Date.now() + 20 * 60 * 1000),
      createdAt: new Date(Date.now() - 8 * 60 * 1000),
    };

    this.memoryQuestions.set(q1.id, q1);
    this.memoryQuestions.set(q2.id, q2);
  }

  private getQuestionTitle(type: RoadQuestionType): string {
    switch (type) {
      case RoadQuestionType.TRAFFIC:
        return 'هل هنالك زحمة؟';
      case RoadQuestionType.ROAD_CONDITION:
        return 'كيف وضع الطريق أمامي؟';
      case RoadQuestionType.ACCIDENT:
        return 'هل يوجد حادث؟';
      case RoadQuestionType.CLOSURE:
        return 'هل يوجد إغلاق للطريق؟';
      case RoadQuestionType.CHECKPOINT:
        return 'هل توجد نقطة تفتيش / سيطرة؟';
      case RoadQuestionType.FUEL_AVAILABILITY:
        return 'هل توجد محطة بنزين متوفر فيها الوقود؟';
      case RoadQuestionType.WATER_FLOOD:
        return 'هل يوجد تجمع مياه أو فيضان؟';
      default:
        return 'استفسار من سائق على الطريق';
    }
  }

  async askQuestion(userId: string, dto: AskRoadQuestionDto) {
    const id = uuidv4();
    const title = this.getQuestionTitle(dto.questionType);
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 mins TTL

    const question = {
      id,
      requesterUserId: userId,
      questionType: dto.questionType,
      title,
      customText: dto.customText || null,
      latitude: dto.latitude,
      longitude: dto.longitude,
      bearing: dto.bearing || 0,
      targetRadiusMeters: 15000,
      roadName: dto.roadName || 'طريق عام',
      roadSegmentId: dto.roadSegmentId || 'default-segment',
      answersYes: 0,
      answersNo: 0,
      answersNotSure: 0,
      totalAnswers: 0,
      isAggregated: false,
      aggregatedSummary: null,
      expiresAt,
      createdAt: new Date(),
    };

    if (this.db.isDbConnected) {
      try {
        await this.db.query(
          `INSERT INTO road_questions
           (id, requester_user_id, question_type, custom_text, location, latitude, longitude, bearing, target_radius_meters, road_name, expires_at)
           VALUES ($1, $2, $3, $4, ST_SetSRID(ST_MakePoint($5, $6), 4326), $6, $5, $7, $8, $9, $10)`,
          [
            id,
            userId,
            dto.questionType,
            dto.customText,
            dto.longitude,
            dto.latitude,
            dto.bearing || 0,
            15000,
            dto.roadName,
            expiresAt,
          ],
        );
      } catch (err: any) {
        this.logger.warn(`Failed to insert road question to DB: ${err.message}`);
      }
    }

    this.memoryQuestions.set(id, question);
    this.realtimeGateway.broadcastRoadCall(question, dto.roadSegmentId);

    return question;
  }

  async getActiveQuestionsForDriver(lat: number, lng: number, driverBearing?: number) {
    const activeList: any[] = [];
    const now = Date.now();

    for (const q of this.memoryQuestions.values()) {
      if (new Date(q.expiresAt).getTime() > now) {
        const dist = GeoUtils.haversineDistance(lat, lng, q.latitude, q.longitude);
        if (dist <= q.targetRadiusMeters) {
          // If driver bearing is provided, verify whether question is in the forward path
          let isAhead = true;
          if (driverBearing !== undefined && driverBearing !== null) {
            isAhead = GeoUtils.isDriverAheadOnSameRoad(
              lat,
              lng,
              driverBearing,
              q.latitude,
              q.longitude,
              q.bearing || undefined,
              65, // allowable angle cone ahead
            );
          }

          if (isAhead || dist < 3000) { // Always show if very close (< 3km)
            activeList.push({
              ...q,
              distanceMeters: Math.round(dist),
              isAheadOnPath: isAhead,
            });
          }
        }
      }
    }

    return activeList.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }

  async answerQuestion(questionId: string, userId: string, dto: AnswerRoadQuestionDto) {
    let question = this.memoryQuestions.get(questionId);

    if (this.db.isDbConnected) {
      try {
        const res = await this.db.query('SELECT * FROM road_questions WHERE id = $1', [questionId]);
        if (res.rows.length > 0) question = res.rows[0];
      } catch (err) {}
    }

    if (!question) {
      throw new NotFoundException('نداء الطريق غير موجود أو انتهت صلاحيته');
    }

    if (!question.respondents) {
      question.respondents = new Set<string>();
    }

    if (question.respondents.has(userId)) {
      return {
        success: true,
        message: 'لقد أجبت على هذا النداء مسبقاً',
        alreadyAnswered: true,
        question,
      };
    }
    question.respondents.add(userId);

    const answerUpper = dto.answer.toUpperCase();
    if (answerUpper === 'YES' || answerUpper === 'نعم' || answerUpper === 'GOOD' || answerUpper === 'جيد') {
      question.answersYes = (question.answersYes || question.answers_yes || 0) + 1;
    } else if (answerUpper === 'NO' || answerUpper === 'لا' || answerUpper === 'POOR' || answerUpper === 'سيئ') {
      question.answersNo = (question.answersNo || question.answers_no || 0) + 1;
    } else {
      question.answersNotSure = (question.answersNotSure || question.answers_not_sure || 0) + 1;
    }

    question.totalAnswers = (question.totalAnswers || question.total_answers || 0) + 1;

    // Aggregation Logic:
    // If >= 3 answers and >= 70% affirmative, produce a summary and auto-promote to Live Report
    if (question.totalAnswers >= 3) {
      question.isAggregated = true;
      const yesRatio = question.answersYes / question.totalAnswers;
      if (yesRatio >= 0.7) {
        question.aggregatedSummary = `🔴 تأكيد محتمل (${question.answersYes} من ${question.totalAnswers} سواق أكدوا)`;

        // Automatically convert to live road report if question is about traffic/accident/checkpoint/closure
        if (!question.aggregatedReportId) {
          let repType = ReportType.HEAVY_TRAFFIC;
          if (question.questionType === RoadQuestionType.ACCIDENT) repType = ReportType.ACCIDENT;
          else if (question.questionType === RoadQuestionType.CHECKPOINT) repType = ReportType.CHECKPOINT;
          else if (question.questionType === RoadQuestionType.CLOSURE) repType = ReportType.CLOSURE;
          else if (question.questionType === RoadQuestionType.WATER_FLOOD) repType = ReportType.WATER_ACCUMULATION;

          const createdReport: any = await this.reportsService.createReport(userId, {
            type: repType,
            latitude: question.latitude,
            longitude: question.longitude,
            roadName: question.roadName,
            roadSegmentId: question.roadSegmentId,
            description: `تم تأكيد البلاغ تلقائياً من خلال نداء الطريق (${question.answersYes} إجابات مؤكدة)`,
          });
          question.aggregatedReportId = createdReport?.id || createdReport?.report?.id;
        }
      } else if (question.answersNo / question.totalAnswers >= 0.7) {
        question.aggregatedSummary = `🟢 الطريق سالك (${question.answersNo} سواق أكدوا عدم وجود مشكلة)`;
      } else {
        question.aggregatedSummary = `🟡 معلومات متباينة (${question.answersYes} نعم، ${question.answersNo} لا)`;
      }
    }

    this.memoryQuestions.set(questionId, question);
    this.realtimeGateway.broadcastRoadCallAnswer(question);

    return {
      success: true,
      message: 'شكراً لمساعدتك السائقين على الطريق!',
      question,
    };
  }
}
