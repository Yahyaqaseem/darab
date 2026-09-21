import { Controller, Get, Post, Body, Param, Query, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery, ApiBearerAuth } from '@nestjs/swagger';
import { PlacesService } from './places.service';
import { CreatePlaceReviewDto, CreatePlaceDto } from './dto/places.dto';
import { AuthGuard } from '@nestjs/passport';

@ApiTags('دليل الأماكن والخدمات (Places & Services)')
@Controller('places')
export class PlacesController {
  constructor(private readonly placesService: PlacesService) {}

  @Get('categories')
  @ApiOperation({ summary: 'جلب تصنيفات الأماكن (ورش، بنجرجية، مطاعم، سطحة...)' })
  async getCategories() {
    return this.placesService.getCategories();
  }

  @Get('search')
  @ApiOperation({ summary: 'البحث متعدد اللغات في الأماكن والورش والخدمات' })
  @ApiQuery({ name: 'q', required: true, type: String, example: 'بنجرجي' })
  @ApiQuery({ name: 'lat', required: false, type: Number, example: 36.1911 })
  @ApiQuery({ name: 'lng', required: false, type: Number, example: 44.0091 })
  async searchPlaces(
    @Query('q') query: string,
    @Query('lat') lat?: number,
    @Query('lng') lng?: number,
  ) {
    return this.placesService.searchPlaces(
      query,
      lat ? Number(lat) : undefined,
      lng ? Number(lng) : undefined,
    );
  }

  @Get('nearby')
  @ApiOperation({ summary: 'جلب الأماكن والخدمات القريبة من موقع السائق' })
  @ApiQuery({ name: 'lat', required: true, type: Number, example: 36.191113 })
  @ApiQuery({ name: 'lng', required: true, type: Number, example: 44.009167 })
  @ApiQuery({ name: 'category', required: false, type: String, example: 'tire_repair' })
  @ApiQuery({ name: 'radius', required: false, type: Number, example: 30000 })
  async getNearbyPlaces(
    @Query('lat') lat: number,
    @Query('lng') lng: number,
    @Query('category') category?: string,
    @Query('radius') radius?: number,
  ) {
    return this.placesService.getNearbyPlaces(
      Number(lat),
      Number(lng),
      category,
      radius ? Number(radius) : 30000,
    );
  }

  @Post()
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'اقتراح أو إضافة ورشة / مكان جديد على الخريطة مع فحص التكرار' })
  async createPlace(@Body() dto: CreatePlaceDto) {
    return this.placesService.createPlace(dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'جلب تفاصيل المكان، التقييمات، وأرقام التواصل' })
  async getPlaceById(@Param('id') id: string) {
    return this.placesService.getPlaceById(id);
  }

  @Post(':id/reviews')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'إضافة تقييم وملاحظة للمكان من سائق موثوق' })
  async addReview(
    @Param('id') id: string,
    @Req() req: any,
    @Body() dto: CreatePlaceReviewDto,
  ) {
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000001';
    return this.placesService.addReview(id, userId, dto);
  }
}
