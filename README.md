raw-recipe
==========

## cook-raw.sh

A script to combine raw file and jpg file into a editable jpg file

- Generate jpg file which includes jpg and raw file: by default, **./jpg** contains converted jpg files; **./final** contains combined jpg file.
```
~$ cook-raw.sh cook
```

- Generate jpg file which includes jpg, raw file and editor process file (let's call it recipe)
```
~$ cook-raw.sh cooked
```

- Check generated jpg file is well cooked or not
```
~$ cook-raw.sh check
```

- Remove temporary folders
```
~$ cook-raw.sh clean
```

- Only convert raw to jpg
```
~$ cook-raw.sh fry
```

- Only zip files
```
~$ cook-raw.sh wrap
```

- Only create new editable jpg
```
~$ cook-raw.sh mix
```

- Extract raw file from editable jpg. A folder **./raw** will be created with all extracted raw files.
```
~$ cook-raw.sh unwrap
```

- Cook one file:
```
~$ cook-raw.sh cookfile <filename>
```

- Run tests
```
~$ cook-raw.sh test
```
