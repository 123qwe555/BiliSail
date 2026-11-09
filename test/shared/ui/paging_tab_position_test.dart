import 'package:bilisail/features/feed/domain/home_channel.dart';
import 'package:bilisail/shared/ui/paging_tab_strip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // What a tablet in landscape shows: compact strip with 直播 inline.
  const strip = [
    HomeChannel.recommended,
    HomeChannel.popular,
    HomeChannel.live,
    HomeChannel.bangumi,
    HomeChannel.guochuang,
    HomeChannel.cinema,
    HomeChannel.categories,
  ];

  // What its pager uses when its own compact rule disagrees: no inline 直播.
  const pagerOrder = [
    HomeChannel.recommended,
    HomeChannel.popular,
    HomeChannel.bangumi,
    HomeChannel.guochuang,
    HomeChannel.cinema,
    HomeChannel.categories,
  ];

  test('a page index is mapped onto the strip that shows an extra channel', () {
    // Page 2 of the pager is 番剧 even though strip index 2 is 直播.
    expect(
      mapPagingPosition(
        order: pagerOrder,
        tabs: strip,
        value: 2,
        fallbackIndex: 0,
      ),
      3,
    );
    // 国创: pager 3, strip 4.
    expect(
      mapPagingPosition(
        order: pagerOrder,
        tabs: strip,
        value: 3,
        fallbackIndex: 0,
      ),
      4,
    );
  });

  test('a mid-swipe position interpolates in strip space', () {
    expect(
      mapPagingPosition(
        order: pagerOrder,
        tabs: strip,
        value: 2.5,
        fallbackIndex: 0,
      ),
      3.5,
    );
  });

  test('matching orders pass the position through unchanged', () {
    expect(
      mapPagingPosition(
        order: strip,
        tabs: strip,
        value: 3,
        fallbackIndex: 0,
      ),
      3,
    );
  });

  test('a channel missing from the strip falls back to the selected index', () {
    expect(
      mapPagingPosition(
        order: const [HomeChannel.dynamic, HomeChannel.videoDynamic],
        tabs: strip,
        value: 0,
        fallbackIndex: 4,
      ),
      4,
    );
  });
}
