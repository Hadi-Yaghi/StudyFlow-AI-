import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/availability_model.dart';

class AvailabilityService {
  final ApiClient _apiClient = ApiClient();

  Future<List<AvailabilityModel>> getUserAvailability() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.availabilityUrl);
      if (response.data is List) {
        return (response.data as List)
            .map((json) => AvailabilityModel.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (_) {
      return [];
    }
  }

  Future<AvailabilityModel?> saveAvailability(AvailabilityModel availability) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.availabilityUrl,
        data: availability.toJson(),
      );
      return AvailabilityModel.fromJson(response.data);
    } on DioException catch (_) {
      return availability;
    }
  }
}
