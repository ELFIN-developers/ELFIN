# ELFIN UNINSTALLING SCRIPT

# VERSION
version=v0
ELFIN=ELFIN${version}

# REMOVE ELFIN FROM HOME DIRECTORY
if [ -d $HOME/$ELFIN ]
then
  echo "Removing all files from $HOME/$ELFIN directory..."
  rm -R $HOME/$ELFIN
else
  echo "NO $HOME/$ELFIN directory found..."
fi

# GETTING RID OF ELFIN SETTINGS IN LOCAL BASHRC
if grep -q ^.*ELFIN_SETTINGS.* $HOME/.bashrc
then
  sed -i "s/^.*ELFIN_SETTINGS.*//g" $HOME/.bashrc
else
  echo "$HOME/.bashrc was clean from PLODX stuff"
fi
# REMOVE FILE .elfinrc FROM HOME DIRECTORY
if [ -f $HOME/.bashrc ]
then 
  rm $HOME/.elfinrc
else
  echo "No $HOME/.elfinrc found..."
fi

echo "$ELFIN WAS SUCCESFULLY UNISTALLED!"