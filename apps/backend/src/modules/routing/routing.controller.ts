import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { RoutingService } from './routing.service';
import { AuthGuard } from '@nestjs/passport';

@Controller('routing')
@UseGuards(AuthGuard('jwt'))
export class RoutingController {
  constructor(private readonly routingService: RoutingService) {}

  @Post('calculate')
  async calculateRoute(@Body() body: { originLat: number; originLng: number; destLat: number; destLng: number }) {
    return this.routingService.calculateRoute(
      body.originLat,
      body.originLng,
      body.destLat,
      body.destLng,
    );
  }
}
