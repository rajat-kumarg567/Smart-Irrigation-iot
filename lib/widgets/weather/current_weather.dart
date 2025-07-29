
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glowstone/glowstone.dart';

import '../../utils/weather.dart';
import 'extra_details.dart';

class CurrentWeather extends StatelessWidget {
  final Map<String, dynamic> snapshot;

  const CurrentWeather({
    Key? key,
    required this.snapshot,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var data = snapshot;
    var current = data["current"];
    var temp = current["temperature_2m"].toStringAsFixed(0);
    var formattedDate = DateTime.parse(current["time"]).toLocal();

    return Container(
      height: MediaQuery.of(context).size.height - 230,
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.only(top: 50, left: 30, right: 30),
      decoration: BoxDecoration(
        color: const Color(0xff00A1FF),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(60),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff00A1FF).withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 20,
            offset: const Offset(0, 0),
          )
        ],
      ),
      child: Column(
        children: [
          Glowstone(
            color: Colors.white,
            radius: 12,
            child: Text(
              data["address"] ?? 'N/A',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            height: 370,
            child: Stack(
              children: [
                Image(
                  image: AssetImage(
                    WeatherUtil.findIcon(current["weather_code"], true),
                  ),
                  height: 256,
                  fit: BoxFit.fill,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Center(
                    child: Column(
                      children: [
                        Glowstone(
                          color: Colors.white,
                          radius: 20,
                          child: Text(
                            '$temp °C',
                            style: const TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          WeatherUtil.getWeatherDescription(current["weather_code"]),
                          style: const TextStyle(fontSize: 25, color: Colors.white),
                        ),
                        Text(
                          WeatherUtil.getFormattedDate(formattedDate),
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          const Divider(color: Colors.white),
          const SizedBox(height: 10),
          ExtraDetails(snapshot: snapshot),
        ],
      ),
    );
  }
}
