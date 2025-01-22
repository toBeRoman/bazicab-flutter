import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TripShimmer extends StatelessWidget {
  const TripShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: ListTile(
              title: Container(
                width: double.infinity,
                height: 16,
                color: Colors.white,
              ),
              subtitle: Container(
                width: 100,
                height: 12,
                margin: const EdgeInsets.only(top: 8),
                color: Colors.white,
              ),
              trailing: Container(
                width: 60,
                height: 16,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
} 