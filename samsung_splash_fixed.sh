#!/bin/bash

DEVICE="unknown"
PIC_META_FILE="up_param_files_${DEVICE}.txt"

if [ "$1" = "" ]; then
  echo "This script helps you create your own up_param file for modifying bootloader splashes on samsung devices."
  echo
  echo "Download the stock firmware, extract it until you have up_param.bin"
  echo "Set your device codename by editing this script. (Currently set to \"$DEVICE\")"
  echo "Then run "
  echo "    $0 processMeta up_param.bin"
  echo "Then a file named \"$PIC_META_FILE\" will appear, which describes the images."
  echo "You can now either:"
  echo "  1. Extract the stock up_param with"
  echo "      $0 decodeBinary up_param.bin"
  echo "      and modify the images"
  echo "  2. Create your own images"
  echo "All images must be .jpg and must be named and have the exact dimensions as described in \"$PIC_META_FILE\""
  echo "Then run "
  echo "    $0 createBinary"
  echo "to convert the images in the same folder to an up_param binary."
  echo "Then finally you can flash the created up_param by calling"
  echo "    $0 uploadBinary $PIC_META_FILE up_param_${DEVICE}_heimdall.bin"
  echo
  echo "Usage:"
  echo "  $0 processMeta <up_param binary from firmware>"
  echo "  $0 decodeBinary <up_param binary>"
  echo "  $0 createBinary [$PIC_META_FILE]"
  echo "  $0 uploadBinary [up_param binary = up_param_${DEVICE}_heimdall.bin] [$PIC_META_FILE]"
  echo "  $0 uploadBinaryUnchecked <up param binary>"
  exit 1
fi

check() {
  if [ ! -f "$(which $1)" ]; then
    echo "$1 not found"
    echo "Please install it. On macOS, try: brew install $1"
    exit 1
  fi
}

check_file() {
  if [ ! -f "$1" ]; then
    echo "$1 not found";
    exit 1
  fi
}

setupFolder() {
  folder="$1"
  if [ -d "$folder" ]; then rm -r $folder; fi
  mkdir $folder
}

processMeta() {
    stock_file="$1"
    check mogrify
    setupFolder files
    cp "$stock_file" "files/up_param_stock.bin" || exit 1
    cd files
    decodeBinary up_param_stock.bin
    #
    # !! 修正 #1：在 processMeta 中修正權限 !!
    chmod u+w *
    #
    rm up_param_stock.bin
    ls | grep -v ".txt" > files.txt
    for file in $(cat files.txt); do
      ext=$(echo "$file" | rev | cut -d'.' -f 1 | rev)
      if [ "$ext" = "jpg" ]; then
        echo "$file:$(mogrify -print "%wx%h" $file)" >> files-new.txt
      else
        check shasum
        checksum=$(shasum -a 256 "$file" | cut -d' ' -f 1)
        echo "$file:$checksum" >> files-new.txt
        cp -f "$file" ..
      fi
    done
    cp -f files-new.txt "../$PIC_META_FILE"
    cd ..
    rm -r files
}

decodeBinary() {
  binary="$1"
  tar xf "$binary"
  #
  # !! 修正 #2：在 decodeBinary 中修正權限 !!
  chmod u+w *
  #
}

case "$1" in
  "processMeta")
    processMeta "$2"
    ;;
  "decodeBinary")
    decodeBinary "$2"
    ;;
  "createBinary")
    if [ ! -z "$2" ]; then PIC_META_FILE=$2; fi
    check mogrify
    check_file "$PIC_META_FILE"
    setupFolder files
    for file in $(cat "$PIC_META_FILE" | cut -d':' -f 1); do
      cp "$file" "files/$file" || exit 1
    done
    cd files
    # 為了保險，這裡也可以再加一次權限修正
    chmod u+w *
    mkdir files
    for filemeta in $(cat "../$PIC_META_FILE"); do
      file=$(echo $filemeta | cut -d':' -f 1)
      ext=$(echo "$file" | rev | cut -d'.' -f 1 | rev)
      if [ "$ext" = "jpg" ]; then
        size=$(echo $filemeta | cut -d':' -f 2)
        actualsize=$(mogrify -print "%wx%h" $file)
        if [ ! "$size" = "$actualsize" ]; then
          echo "$file dimensions are $actualsize, but should be $size, correcting automatically!"
          mogrify -resize "${size}!" "$file" || exit 1
        fi
      else
        check shasum
        checksum=$(echo $filemeta | cut -d':' -f 2)
        actualchecksum=$(shasum -a 256 "$file" | cut -d' ' -f 1)
        if [ "$checksum" != "$actualchecksum" ]; then
          echo "Checksum for $file does not match!"
          echo "  Expected: $checksum"
          echo "  Actual:   $actualchecksum"
          exit 1
        fi
      fi
      cp "$file" files
    done
    cd files
    tar cf up_param.bin * || exit 1
    cp up_param.bin ..
    cd ..
    cp -f up_param.bin "../up_param_${DEVICE}_heimdall.bin"
    # tar for odin
    tar cf up_param.tar up_param.bin && cp -f up_param.tar "../up_param_${DEVICE}_odin.tar"
    cd ..
    rm -r files
    exit 0
    ;;
  "uploadBinary")
    UPLOADFILE="$2"
    if [ -z "$UPLOADFILE" ]; then UPLOADFILE="up_param_${DEVICE}_heimdall.bin"; fi
    if [ ! -z "$3" ]; then PIC_META_FILE="$3"; fi
    check_file $PIC_META_FILE
    setupFolder files
    cp "$UPLOADFILE" files/up_param.bin || exit 1
    cd files
    tar xf up_param.bin || exit 1
    for filemeta in $(cat "../$PIC_META_FILE"); do
      file=$(echo $filemeta | cut -d':' -f 1)
      ext=$(echo "$file" | rev | cut -d'.' -f 1 | rev)
      if [ "$ext" = "jpg" ]; then
        size=$(echo $filemeta | cut -d':' -f 2)
        actualsize=$(mogrify -print "%wx%h" $file)
        if [ ! "$size" = "$actualsize" ]; then
          echo "$file dimensions are $actualsize, but should be $size!"
          cd ..
          rm -r files
          exit 1
        fi
      else
        check shasum
        checksum=$(echo $filemeta | cut -d':' -f 2)
        actualchecksum=$(shasum -a 256 "$file" | cut -d' ' -f 1)
        if [ "$checksum" != "$actualchecksum" ]; then
          echo "Checksum for $file does not match!"
          echo "  Expected: $checksum"
          echo "  Actual:   $actualchecksum"
          exit 1
        fi
      fi
    done
    cd ..
    rm -r files
    $0 uploadBinaryUnchecked "$UPLOADFILE"
    exit 0
    ;;
  "uploadBinaryUnchecked")
    check heimdall
    check_file "$2"
    heimdall flash --UP_PARAM "$2"
    exit 0
    ;;
  *)
    $0
    exit 1
    ;;
esac