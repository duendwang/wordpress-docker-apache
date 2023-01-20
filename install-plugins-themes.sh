#!bin/bash

echo "Make sure you are using bash to run the script, not sh."
echo "bash ./<name> or ./<name> is fine, but not sh ./<name>."
echo ""

echo "What Wordpress Docker container are we working with?"
echo ""

i=0

for AVAILABLE_CONTAINER in $(docker ps -f name=wordpress --format \"{{.Names}}\");
do
  echo "$((i+1))) $AVAILABLE_CONTAINER"
  AVAILABLE_CONTAINERS[$i]="$(echo $AVAILABLE_CONTAINER | tr -d '\"')"
  i=$((i+=1))
done

read SELECTED_CONTAINER_NUMBER

SELECTED_CONTAINER=${AVAILABLE_CONTAINERS[$((SELECTED_CONTAINER_NUMBER-1))]}

echo $SELECTED_CONTAINER

if [ ! "$(docker top $SELECTED_CONTAINER)" ]
then
  echo "The container either does not exist or is not running."
  exit 1
fi

cd /home/ubuntu/websites/Themes

if [ "$(ls | wc -l)" > 0 ]
then
  echo "**THEMES**"
  for THEME in */ ;
  do
    THEME="${THEME%/}"
    echo "Do you want to add the $THEME theme to the $SELECTED_CONTAINER container? [y,n,a]"
    read THEME_PROMPT
    case $THEME_PROMPT in
      y)
        {
          docker cp $THEME $SELECTED_CONTAINER:/var/www/html/wp-content/themes/$THEME && echo "Copied theme $THEME to $SELECTED_CONTAINER";\
        } || { echo "Could not copy theme $THEME to $SELECTED_CONTAINER"; }
        echo ""
        ;;
      n)
        continue
        ;;
      a)
        exit 0
        ;;
    esac
  done
else
  echo "No themes found."
  echo ""
fi

cd /home/ubuntu/websites/Plugins

if [ "$(ls | wc -l)" > 0 ]
then
  echo "**PLUGINS**"
  for PLUGIN in */ ;
  do
    PLUGIN="${PLUGIN%/}"
    echo "Do you want to add the $PLUGIN plugin to the $SELECTED_CONTAINER container? [y,n,a]"
    read PLUGIN_PROMPT
    case $PLUGIN_PROMPT in
      y)
        {
          docker cp "$PLUGIN" "$SELECTED_CONTAINER":/var/www/html/wp-content/plugins/"$PLUGIN" && echo "Copied plugin $PLUGIN to $SELECTED_CONTAINER container" ;
        } || { echo "Could not copy plugin $PLUGIN to $SELECTED_CONTAINER" ; }
        echo ""
        ;;
      n)
        continue
        ;;
      a)
        exit 0
        ;;
    esac
  done
else
  echo "No plugins found."
  echo ""
fi

{
  docker exec $SELECTED_CONTAINER /bin/bash -c "chown www-data:www-data -R /var/www/html/wp-content/themes/*" && echo "Successfully changed ownership of theme files to www-data"
} || {
  echo "Failed to change ownership of theme files to www-data"
}

{
  docker exec $SELECTED_CONTAINER /bin/bash -c "chown www-data:www-data -R /var/www/html/wp-content/plugins/*" && echo "Successfully changed ownership of plugin files to www-data"
} || {
  echo "Failed to change ownership of plugin files to www-data"
}

{
  docker exec $SELECTED_CONTAINER /bin/bash -c "find /var/www/html/ -type f -exec chmod 604 {} \;"  && echo "Successfully changed permissions of wordpress files"
} || {
  echo "Failed to change permissions of wordpress files"
}

{
  docker exec $SELECTED_CONTAINER /bin/bash -c "find /var/www/html/ -type d -exec chmod 705 {} \;" &&  echo "Successfully changed permissions of wordpress folders"
} || {
  echo "Failed to change permissions of wordpress folders"
}

echo "Done"
