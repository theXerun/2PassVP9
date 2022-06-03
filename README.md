# About

This script helps convert an existing video file to a vp9 webm of set size with ffmpeg, which really helps if you use websites or services such as Discord which have an upload filesize limit. It uses a simple 2pass equasion:

```(Desired Size in Megabytes * 8192) / Total Length in Seconds = Available bandwith```

The audio has a set bandwith of 64k (libopus) and this value is subtracted from available bandwith to calculate video bitrate.

The ffmpeg command used is mostly copied from [this reddit post](https://www.reddit.com/r/AV1/comments/k7colv/encoder_tuning_part_1_tuning_libvpxvp9_be_more/) because the default libvpx-vp9 settings suck and I don't have enough time to delve into these things myself.


# Options

- `-i` File input (mandatory for obvious reasons).
- `-u` New frame height. Width is calculated by aspect ratio automatically by ffmpeg.
- `-s` Desired size in MB. Default is 8, because discord is a thing.
- `-o` Output filename. Keep in mind that if a file with the same name already exists, the script will exit.

# Other stuff worth mentioning

Please notify me if you spot any glaring issues in the script, I'm not a pro bash scripter so they might be there.

Also feel free to make any requests ;)

