# ---+ Extensions
# ---++ GraphvizPlugin
# This is the configuration used by the <b>GraphvizPlugin</b>.

# **STRING**
$Foswiki::cfg{GraphvizPlugin}{DotCmd} = '/usr/bin/dot -K%RENDERER|S% -T%TYPE|S% -o%OUTFILE|F% %INFILE|F%';

# **STRING**
$Foswiki::cfg{GraphvizPlugin}{ImageFormat} = '<noautolink><img src=\'$url\' class=\'graphviz\' $style$width$height/></noautolink>';

1;
