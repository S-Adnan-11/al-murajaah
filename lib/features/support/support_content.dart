import '../../core/audio/sample_catalog.dart';
import '../../core/audio/session_spec.dart';
import '../../core/audio/recording_source.dart';

const developerWebsite = 'https://s-adnan.dev';
const developerName = 'S. Adnan';
const developerGithub = 'https://github.com/S-Adnan-11';
const storyApproved = true;
const originStory = r''' بسم الله الرحمن الرحيم

So, Nas was telling me about how he's keeping up with Ḥifż, Murājaʿah and Karatu in general during his SIWES placement, yani civil engineering internship stuff.

Between school, site work, structural engineering meetings, travelling back and forth etc. he was still finding time for the karatu. That determination is something I admire about him.

His said workaround was to screen-record his phone while playing a part he wanted to revise or memorize, then convert the videos to audio and listen to those audios on repeat, before then sitting to memorize properly.

Then, one day he told me hadn't made (I think) revision or memorization because he didn't screen-record yet. I thought about it: yani he had to screen-record and convert it to audio, before he'd then delete the video.
I felt that's soo time and memory inefficient..

I did have the Idea for an app before like this before, so after that conversation, I then decided to lock in and finally build it, bi iznillah, yani: a way to choose a passage, listen on repeat, save it, and return to it without recording anything again, and ofc here, Goni Bukar Zarami is the preferred reciter. May Allah ﷻ grant him abundant reward.

tho I did outsource to Shaykh Umar Idris and Shaykh Yahaya Ibrahim Muhammad for surahs where Shaykh Muhammad Zarami's audio was faulty. May Allah ﷻ reward them all.

also back then, I found Al-Muḥaffiz and El-Moḥaffez but they had limitations and I couldn't configure the preferred Qāri
also some Muarratal, Mujawwad settings that didn't suit what I was intending.

So we built this...

فَسَمَّيْنَاهُ الْمُرَاجَعَة

...and it became Al-Murāja'ah.

Wa lillahil hamd.

Nas didn’t even know I’d started working on it after we spoke. The final release is would..

His Shaykh Abdulrahman, may Allah ﷻ preserve him, once he gave them an advice on a methodology which we're inclined to. He said*,* :

[The means to learning is repetition, the means to memorizing is repetition and the means to retaining what you memorized is repetition.]

That advice captures much of what this app is here to help with. And since you found this little corner, I’ve included a few recitations from Nasir and Abdulrahman for you.

I began this to make things a little easier for my little brother. We also hope it's beneficial to the ummah and we hope in the ajr (reward) from Allah ﷻ 🤲.

And Allah ﷻ is the source of strength.

ولله الحمد والصلاة والسلام على رسول الله



✍️
S. Adnan
13.04.1448
24.09.2026
''';

/// Only owner-supplied, inspected, versioned recordings belong here.
const storyRecordings = <StoryRecording>[
  StoryRecording(
    SampleAsset(
      'brother-001',
      'Al-Hajj · Closing recitation',
      'https://res.cloudinary.com/yw5eprsc/video/upload/v1791645967/E1-Nas-Hajj-end.mp3',
      3879749,
      '2c4ac4ebeb052d7feb67e776ffa457fc74ef8ab045331af301b7c8429da07cb3',
      reciter: 'Nasir',
      riwayah: null,
    ),
    96920,
  ),
  StoryRecording(
    SampleAsset(
      'brother-002',
      'Ibrahim · Excerpt',
      'https://res.cloudinary.com/yw5eprsc/video/upload/v1791645951/E2-Nas-Ibrahim-part.mp3',
      832826,
      'e038674efe8b729239d3c8ef1e217d34ded0c91c2a60461e8bcaa7ac17b74804',
      reciter: 'Nasir',
      riwayah: null,
    ),
    20754,
  ),
  StoryRecording(
    SampleAsset(
      'brother-003',
      'An-Nur · Excerpt',
      'https://res.cloudinary.com/yw5eprsc/video/upload/v1791645961/E3-Nas-Nuur-part.mp3',
      1766965,
      '13c887e287718a4a8e9cdefc1b4f4f19f4603d6494c1aa3bd235f58b681ac591',
      reciter: 'Nasir',
      riwayah: null,
    ),
    44114,
  ),
  StoryRecording(
    SampleAsset(
      'origin-004',
      'Al-Hajj · Closing recitation',
      'https://res.cloudinary.com/yw5eprsc/video/upload/v1791645964/E4-Sh-Abdulrahman-Hajj-end.mp3',
      3277991,
      '3ffe517d6b7555c6301b5c96603547eb8a5366a7daaceefe3a9c6c2cdaf7b9ec',
      reciter: 'Shaykh Abdulrahman',
      riwayah: null,
    ),
    81874,
  ),
];

class StoryRecording extends RecordingSource {
  const StoryRecording(this.asset, this.durationMs);
  final SampleAsset asset;
  @override
  final int durationMs;
  @override
  String get assetId => asset.id;
  @override
  String get name => asset.name;
  String get creditName => '$name · ${asset.reciter}';
  @override
  int get byteSize => asset.bytes;
  @override
  SampleAsset get audioAsset => asset;
  @override
  bool get available => valid;
  @override
  String? get unavailableReason => valid ? null : 'Recitation unavailable';
  bool get valid =>
      RegExp(r'^(brother|origin)-\d{3}$').hasMatch(asset.id) &&
      Uri.tryParse(asset.url)?.scheme == 'https' &&
      asset.reciter.trim().isNotEmpty &&
      asset.bytes > 0 &&
      durationMs >= 1000 &&
      RegExp(r'^[a-f0-9]{64}$').hasMatch(asset.sha256);
  SessionSpec get session =>
      SessionSpec(assetId: asset.id, durationMs: durationMs);
}
