package MyTNS;

use strict;
use warnings;

###########################################################################################
# Auteur      : Christian MOISE
# Nom         : MyTNS.pm
# Mise a jour : 2017/07/12
# Objet       : gestion des entrees des fichiers tnsnames.ora
###########################################################################################

# ==========================================================================================================================
sub new {
  my ($class, $file) = @_;

  my $self = {
    file => $file,
    _buffer => ""
  };

  bless $self, $class;

  open(my $file_id, $file) || return 0;
  while (<$file_id>) {
    $self->{_buffer}=$self->{_buffer}.$_;
  }
  close($file_id);

  return $self;
}

# ====================================================================================================
our $alias="([a-z] | [a-z][\\w\\.-]*[^\\.])";

our $key="[a-z][\\w-]+";     # une cle commence par une lettre suivi par des \w ou '-'

our $value="[^\\s\\(\\)]+";  # une valeur est tout sauf un espace ou une paranthese

our $couple="\\( \\s* $key \\s* = \\s* $value \\s* \\)";
# exemple : (PROTOCOL=tcp)

our $serie1="(\\s* $couple)+";
# exemple: (PROTOCOL=tcp)(HOST=host1)(PORT=1630)

our $serie2="\\( \\s* $key \\s* = $serie1 \\s* \\)";
# exemple: (ADDRESS=(PROTOCOL=tcp)(HOST=host1)(PORT=1630))

our $serie3="($serie1 | \\s* $serie2)+";
# exemple: (FAILOVER=on)(LOAD_BALANCE=off)
#          (ADDRESS=(PROTOCOL=tcp)(HOST=host2a)(PORT=1630))
#          (ADDRESS=(PROTOCOL=tcp)(HOST=host2b)(PORT=1630))

our $serie4="\\( \\s* $key \\s* = $serie3 \\s* \\)";
# exemple: (ADDRESS_LIST= (FAILOVER=on)(LOAD_BALANCE=off)
#            (ADDRESS=(PROTOCOL=tcp)(HOST=host2a)(PORT=1630))
#            (ADDRESS=(PROTOCOL=tcp)(HOST=host2b)(PORT=1630)))

our $description="\\( \\s* DESCRIPTION \\s* = ($serie3|\\s* $serie4)+ \\s* \\)";

our $description_list="\\( \\s* DESCRIPTION_LIST \\s* = (\\s* $description)+ \\s* \\)";

# ====================================================================================================
sub _remove_comments {
  my ($self, $buffer) = @_;

  $buffer=~s/\s*#[^\n]*\n/\n/g;  # suppression des commentaires

  return $buffer;
}

# ====================================================================================================
# ----- check -----
sub check {
  my ($self, $buffer) = @_;

  $buffer=$buffer || $self->{_buffer};
  $buffer=" ".$buffer;

  $buffer=$self->_remove_comments($buffer);

  if ($buffer=~m/^\s*$/s) { return 0; }  # si le fichier est vide

  my $entry="$alias(\\s*,\\s* $alias)* \\s* = \\s* ($description|$description_list)";

  if ($buffer=~m/^ (\s+ $entry)+ \s*$/isx) { return 0; }

  return 1;
}

# ====================================================================================================
# ----- check -----
sub exists {
  my ($self, $tns) = @_;

  my $buffer=" ".$self->{_buffer};

  $buffer=$self->_remove_comments($buffer);

  if ($buffer=~m/ \s ($alias \s*,)*$tns(\s*,\s* $alias)* \s* = \s* ($description|$description_list)/isx) {
    return 1;
  }

  return 0;
}

# ====================================================================================================
# ----- remove -----
sub remove {
  my ($self, $tns) = @_;

  my $rc=$self->check();

  if ($rc) { return $rc; }

  $rc=1;

  my $buffer="";
  my $string="";  # chaine correspondant au a l'entree tns
  my $found=0;

  foreach my $line (split(/\n/, $self->{_buffer})) {
    if ((! $found) && ($line=~m/^ \s* ($alias \s*,)*$tns(\s*,\s* $alias)* \s* (\n|=)/ix)) { $found=1; }

    if (! $found) {
      $buffer=$buffer.$line."\n";
      next;
    }

    $line=$self->_remove_comments($line);
    $string=$string.$line."\n";
    if ($self->check($string) == 0) {
      $string="";
      $found=0;
      $rc=0;
    }
  }

  $self->{_buffer}=$buffer;

  return $rc;
}

# ====================================================================================================
# ----- add -----
sub add {
  my ($self, %args) = @_;

  my $string=$args{string} || "";
  my $alias=$args{alias} || "";
  my $host=$args{host} || "";
  my $port=$args{port} || 1521;
  my $service_name=$args{service_name} || "";

  if ($string) {
    if ($self->check($string) == 0) {
      $self->{_buffer}=$self->{_buffer}."\n\n".$string;

      return 0;
    }
    return 1;
  }
  elsif (($alias) && ($host) && ($service_name)) {
    $string="$alias=
    (DESCRIPTION=
      (ADDRESS=(PROTOCOL=tcp)(HOST=$host)(PORT=$port))
      (CONNECT_DATA=(SERVICE_NAME=$service_name)))\n";

    return $self->add("string"=>$string);
  }

  return 1;
}

# ==========================================================================================================================
sub commit {
  my ($self) = @_;

  open(my $file_id, ">$self->{file}") || return 1;
  print $file_id $self->{_buffer};
  close($file_id);

  return 0;
}

1;

