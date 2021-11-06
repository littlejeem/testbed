#!/usr/bin/env bash
source /usr/local/bin/helper_script.sh
source /usr/local/bin/config.sh
verbosity=6
usb_uuid="6185-9FC6"
usb_transfer_mount="/mnt/transfer_drive"
lockname="mount_play"
pushover_title="USB AutoSync Script"
#
#
exit_segment ()
{
umount "$mountpoint"
if [[ $? -eq 0 ]]; then
  enotify "SUCCESS - sync completed"
  edebug "USB Drive $mountpoint unmounted"
  message_form=$(echo "SUCCESS - Sync completed, unplug the drive, your goodies are ready!")
  edebug "Message_form would be: $message_form"
  pushover > /dev/null
else
  ecrit "FAILURE - umount returned error: $?"
  exit 66
fi
}
#
#
grep -qs "$usb_transfer_mount" /proc/mounts #if grep sees the mount then it will return a silent 0 if not seen a silent 1
if [[ $? -eq 0 ]]; then
  edebug "USB Drive already mounted"
  mountpoint=$(grep "$usb_transfer_mount" /proc/mounts | cut -c 1-9)
  enotify "mountpoint is $mountpoint"
  message_form=$(echo "USB DETECTED - Sync starting, please wait...")
  edebug "Message form would be: $message_form"
  pushover > /dev/null
  edebug "we'd do some rsync stuff here"
  exit_segment
elif [[ $? -eq 1 ]]; then
    edebug "USB Drive NOT currently mounted."
    if mount -U "$usb_uuid" "$usb_transfer_mount"; then
      mountpoint=$(grep "$usb_transfer_mount" /proc/mounts | cut -c 1-9)
      edebug "USB Drive mounted successfully"
      message_form=$(echo "USB DETECTED - Sync starting, please wait...")
      edebug "Message form would be: $message_form"
      pushover > /dev/null
      edebug "do some rsync stuff here"
      exit_segment
    else
      eerror "Something went wrong with the mount of the USB..."
      message_form=$(echo "ERROR - Script started but Something went wrong mounting the USB...contact your administrator!")
      edebug "Message_form would be: $message_form"
      pushover > /dev/null
      exit 66
    fi
fi
