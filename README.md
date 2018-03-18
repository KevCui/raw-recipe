raw-recipe
==========

This is a collection of Bash scripts, which are used to better cook RAW files from camera.

## cook-raw.sh

A script to combine raw file and jpg file into a editable jpg file

- Generate jpg file which includes jpg and raw file: by default, **./jpg** contains converted jpg files; **./final** contains combined jpg file.
```
~$ cook-raw.sh cook
```

- Check generated jpg file is well cooked or not
```
~$ cook-raw.sh check
```

- Remove temporary folders
```
~$ cook-raw.sh clean
```

- Cook + Check
```
~$ cook-raw.sh
```
## uncook-raw.sh

A script to extract raw file from editable jpg. A folder **./raw** will be created with all extracted raw files.
```
~$ uncook-raw.sh
```
