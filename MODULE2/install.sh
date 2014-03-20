# ELFIN INSTALLING SCRIPT

# VERSION
version=v0
ELFIN=ELFIN${version}

# MOVE FILES & DIRECTORIES TO HOME
if [ -d $HOME/$ELFIN ]
then
  # CHECK IF OLDER VERSIONS EXIST IN HOME DIRECTORY
  echo "Please remove old version $HOME/$ELFIN and try again..."
  exit
else
  mkdir $HOME/$ELFIN
  cp -r * $HOME/$ELFIN
  # SET DIR AND ALIAS TO CURRENT TERMINAL AND LOCAL BASHRC
  # CLEAN .BASHRC FILE FROM PREVIOUS ELFIN SETTINGS
  if grep -q ^.*ELFIN_SETTINGS.* $HOME/.bashrc
  then
    sed -i "s/^.*ELFIN_SETTINGS.*//g" $HOME/.bashrc
  fi
  # CHECK EARLIER INSTALLATION & CREATE ELFINRC FILE
  if [ -f $HOME/.elfinrc ]
  then
    echo -e "\nTHIS IS NOT THE FIRST TIME YOU INSTALL ELFIN IN THIS COMPUTER"
    echo -e "JUST MAKE SURE YOU'VE REMOVED OLD ELFIN PACKAGES FROM DIR $HOME\n"
  fi
  echo "# SET DIR AND ALIAS FOR ELFIN # ELFIN_SETTINGS" > $HOME/.elfinrc
  echo "export ELFINDIR=$HOME/$ELFIN/bin # ELFIN_SETTINGS" >> $HOME/.elfinrc
  echo "alias ELFIN='bash $HOME/$ELFIN/bin/ELFIN.sh' # ELFIN_SETTINGS" >> $HOME/.elfinrc
  echo -n "source ~/.elfinrc # ELFIN_SETTINGS" >> $HOME/.bashrc

  echo -e "\n$ELFIN package files were succesfully created at $HOME/$ELFIN"
  echo -e "Open up a new terminal window, type ELFIN and enjoy!!!\n"
  rm $HOME/$ELFIN/install.sh 
  rm $HOME/$ELFIN/Miscellaneous/README.odt
fi







