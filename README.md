Tiny backup tool, which allow you to save files and directory, while you need edit them.  
Support multiple backups for one file.  

## Installation  
You can clone repository and run `install.sh` script, but it will be easier to use one-liners:
* Wget  
`wget -O backuper https://raw.githubusercontent.com/rostegg/backuper/master/backuper.sh && chmod +x backuper && sudo mv backuper /usr/bin/backuper`  
* cURL  
`curl https://raw.githubusercontent.com/rostegg/backuper/master/backuper.sh --output backuper && chmod +x backuper && sudo mv backuper /usr/bin/backuper`  

## Usage
Utility works like an git, creating a hidden directory in which all backups are stored.  
After restor, backup is deleted.  

```
backuper [info|backup|restore|clear]

Options:
    info, i       <file_name>(optional)                 Get info about backups (if file not specified, show info about all backups in directory)
    backup, b     <file_name>                           Make backup of selected file or directory
    restore, r    <file_name> <restore_id>(optional)    Restore file from backup by id, (if id not specified, restore last backup)
    clear, c      <file_name>(optional)                 Remove backups for selected file (if file not specified, remove all backups for current directory)                         
```

## Examples
* Create backup for selected file  
`backuper backup file`  
* Create backup for selected file using short alias
`backuper b file`  
* Show info about backups in current directory  
`backuper info`  
* Show info about backups of selected file  
`backuper info filename`  
* Clear all backups in current directory  
`backuper clear`  
* Restore file by id  
`backuper restore filename 1`  
* Restore file from last backup  
`backuper restore filename`   
  
