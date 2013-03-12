#!/usr/bin/perl -w
#Código aberto
#Direitos: is4web.com Sistemas
#Use-o por conta e risco
use CGI::Carp qw(fatalsToBrowser set_message);   # IMPRIME ERROS

sub dir{ $root = __FILE__;$root =~ s/(\\|\/)?registro\.cgi//;return $root || '.';}

#use strict;
use lib dir;
use CGI qw(:standard);

use vars qw[ $q $epp_user $epp_pwd $epp_port $epp_host $epp_certpwd ];
require 'registroBR.cgi'; #Subs
require 'config.conf'; #Configs

print "Content-type:text/plain\n\n";
eval {
	$q = CGI->new();            

	$RegistroBR::Epp::DEBUG = $q->param('debug'); 
	
	my $url = $q->param('url_retorno');
	my $query;

	foreach ($q->param) {
		$query .= "$_|".$q->param($_)."\n";
	}

	if ($q->param('funcao') eq "querydom"){
		my $fdom = iso2puny($q->param('dominio'));
		my ($avail, $motivo, $error) = epp_availdomain($fdom);
		print "disponivel|$avail\nmotivo|$motivo\nerror|$error\n".$query;
	}

	if ($q->param('funcao') eq "queryorg"){
		my $oid = $q->param('cnpj');
		my ($avo, $motivo, $error) = epp_availorg($oid);
		print  "disponivel|$avo\nmotivo|$motivo\nerror|$error\n".$query;
	}

	if ($q->param('funcao') eq "querycontact"){
		my $brid = $q->param('contatoid');
		my ($avc, $motivo, $error) = epp_availcontact($brid);
		print  "disponivel|$avc\nmotivo|$motivo\nerror|$error\n".$query;
	}

	if ($q->param('funcao') eq "addcontact"){
		my ($brid, $error) = epp_addcontact(iso2utf8($q->param('name')),iso2utf8($q->param('endereco')),iso2utf8($q->param('numero')),iso2utf8($q->param('complemento')),iso2utf8($q->param('cidade')),iso2utf8($q->param('estado')),iso2utf8($q->param('cep')),iso2utf8($q->param('pais')),iso2utf8($q->param('telefone')),iso2utf8($q->param('ramal')),iso2utf8($q->param('email')));
		print  "contato|$brid\nerror|$error\n".$query;
	}

	if ($q->param('funcao') eq "addorg"){
		my ($oid, $error) = epp_addorg($q->param('cnpj'),$q->param('contato'),iso2utf8($q->param('responsavel')),iso2utf8($q->param('empresa')),iso2utf8($q->param('endereco')),$q->param('numero'),iso2utf8($q->param('complemento')),iso2utf8($q->param('cidade')),iso2utf8($q->param('estado')),iso2utf8($q->param('cep')),iso2utf8($q->param('pais')),iso2utf8($q->param('telefone')),iso2utf8($q->param('ramal')),iso2utf8($q->param('email')));
		print "CNPJ|$oid\nerror|$error\n".$query;
	}

	if ($q->param('funcao') eq "adddom"){
		my $fdom = iso2puny($q->param('dominio'));
		my ($ticket, $error) = epp_adddomain($fdom,$q->param('cnpj'),$q->param('unidade'),$q->param('periodo'),$q->param('renew'),$q->param('ns1'),$q->param('ns1ip'),'',$q->param('ns2'),$q->param('ns2ip'),'');
		print "ticket|$ticket\nerror|$error\n".$query;
	}

	if ($q->param('funcao') eq "poll"){
		my $opt = $q->param('opt'); #req ou ack
		my ($id, $msg, $error) = epp_poll($opt,$q->param('msgid'));
		print "msgid|$id\n";
		foreach (keys %$msg) {
			print "$_|$msg->{$_}\n";
		}
		print "error|$error\n".$query;
	}

	if ($q->param('funcao') eq "updatedom"){
		my $fdom = iso2puny($q->param('dominio'));
		my ($ok, $error) = epp_updatedom($fdom,$q->param('auto_renew'),$q->param('tech_id'),$q->param('admin_id'),$q->param('bill_id'),'','',$q->param('ns1'),$q->param('ns1ip'),'',$q->param('ns2'),$q->param('ns2ip'),'','','','','','','','','','',
									$q->param('tech_id_r'),$q->param('admin_id_r'),$q->param('bill_id_r'),'','',$q->param('ns1_r'),$q->param('ns1ip_r'),'',$q->param('ns2_r'),$q->param('ns2ip_r'),'','','','','','','','','','');
		print "update|$ok\nerror|$error\n".$query;
	}

	if ($q->param('funcao') eq "updateorg"){
		my $fdom = iso2puny($q->param('dominio'));
		my ($ok, $error) = epp_updateorg($q->param('cnpj'),$q->param('contato'),$q->param('contato_r'),iso2utf8($q->param('responsavel')),iso2utf8($q->param('empresa')),iso2utf8($q->param('endereco')),$q->param('numero'),iso2utf8($q->param('complemento')),iso2utf8($q->param('cidade')),iso2utf8($q->param('estado')),iso2utf8($q->param('cep')),iso2utf8($q->param('pais')),iso2utf8($q->param('telefone')),iso2utf8($q->param('ramal')),iso2utf8($q->param('email')));
		print "update|$ok\nerror|$error\n".$query;
	}

	if ($q->param('funcao') eq "updateticket"){
		my $fdom = iso2puny($q->param('dominio'));
		my ($ok, $error) = epp_updateticket($fdom,$q->param('ticket'),$q->param('auto_renew'),$q->param('tech_id'),$q->param('admin_id'),$q->param('bill_id'),'','',$q->param('ns1'),$q->param('ns1ip'),'',$q->param('ns2'),$q->param('ns2ip'),'','','','','','','','','','',
									$q->param('tech_id_r'),$q->param('admin_id_r'),$q->param('bill_id_r'),'','',$q->param('ns1_r'),$q->param('ns1ip_r'),'',$q->param('ns2_r'),$q->param('ns2ip_r'),'','','','','','','','','','');
		print "update|$ok\nerror|$error\n".$query;
	}

	if ($q->param('funcao') eq "infoticket"){
		my $fdom = iso2puny($q->param('dominio'));
		my ($xml, $error) = epp_infoticket($fdom,$q->param('ticket'));

		foreach (keys %$xml) {
			$query .= "$_|";
			if (ref ($xml->{$_}) eq "HASH") {
				$query .= hash_values($xml->{$_});
			} elsif (ref ($xml->{$_}) eq "ARRAY") {
				$query .= array_values($xml->{$_});
			} else {
				$query .= $xml->{$_}."::";
			}
			$query .= "\n";
		}

		print "error|$error\n".$query;
	}

	if ($q->param('funcao') eq "infodom"){
		my $fdom = iso2puny($q->param('dominio'));
		my ($xml, $ext, $error) = epp_infodom($fdom);

		foreach (keys %$xml) {
			$query .= "$_|";
			if (ref ($xml->{$_}) eq "HASH") {
				$query .= hash_values($xml->{$_});
			} elsif (ref ($xml->{$_}) eq "ARRAY") {
				$query .= array_values($xml->{$_});
			} else {
				$query .= $xml->{$_}."::";
			}
			$query .= "\n";
		}
		foreach (keys %$ext) {
			$query .= "$_|";
			if (ref ($ext->{$_}) eq "HASH") {
				$query .= hash_values($ext->{$_});
			} elsif (ref ($ext->{$_}) eq "ARRAY") {
				$query .= array_values($ext->{$_});
			} else {
				$query .= $ext->{$_}."::";
			}
			$query .= "\n";
		}

		print "error|$error\n".$query;
	}

	if ($q->param('funcao') eq "infocontact"){
		my $brid = $q->param('contatoid');
		my ($xml, $error) = epp_infocontact($brid);

		foreach (keys %$xml) {
			$query .= "$_|";
			if (ref ($xml->{$_}) eq "HASH") {
				$query .= hash_values($xml->{$_});
			} elsif (ref ($xml->{$_}) eq "ARRAY") {
				$query .= array_values($xml->{$_});
			} else {
				$query .= $xml->{$_}."::";
			}
			$query .= "\n";
		}

		print "error|$error\n".$query;
	}

	if ($q->param('funcao') eq "infoorg"){
		my $oid = $q->param('cnpj');
		my ($xml, $ext, $error) = epp_infoorg($oid);

		foreach (keys %$xml) {
			$query .= "$_|";
			if (ref ($xml->{$_}) eq "HASH") {
				$query .= hash_values($xml->{$_});
			} elsif (ref ($xml->{$_}) eq "ARRAY") {
				$query .= array_values($xml->{$_});
			} else {
				$query .= $xml->{$_}."::";
			}
			$query .= "\n";
		}
		foreach (keys %$ext) {
			$query .= "$_|";
			if (ref ($ext->{$_}) eq "HASH") {
				$query .= hash_values($ext->{$_});
			} elsif (ref ($ext->{$_}) eq "ARRAY") {
				$query .= array_values($ext->{$_});
			} else {
				$query .= $ext->{$_}."::";
			}
			$query .= "\n";
		}

		print "error|$error\n".$query;
	}

	if ($q->param('funcao') eq "renewdom"){
		my $fdom = iso2puny($q->param('dominio'));
		my ($exp, $error) = epp_renew($fdom,$q->param('data_exp'),$q->param('qtd'),$q->param('tipo'));
		print "data_exp|$exp\nerror|$error\n".$query;
	}

	if ($q->param('funcao') eq "teste"){
		my ($return) = teste();
		print "|$return\n".$query;
	}

#	print "\n\n";
};

if ($@) { 
die "$@";
}

#Redefinindo o CGI
package CGI;
	sub param {
		my($self,@p) = self_or_default(@_);
		return $self->all_parameters unless @p;
		my($name,$value,@other);

		# For compatibility between old calling style and use_named_parameters() style, 
		# we have to special case for a single parameter present.
		if (@p > 1) {
		($name,$value,@other) = rearrange([NAME,[DEFAULT,VALUE,VALUES]],@p);
		my(@values);

		if (substr($p[0],0,1) eq '-') {
			@values = defined($value) ? (ref($value) && ref($value) eq 'ARRAY' ? @{$value} : $value) : ();
		} else {
			for ($value,@other) {
			push(@values,$_) if defined($_);
			}
		}
		# If values is provided, then we set it.
		if (@values or defined $value) {
			$self->add_parameter($name);
			$self->{param}{$name}=[@values];
		}
		} else {
		$name = $p[0];
		}

		return "" unless defined($name) && $self->{param}{$name};

		my @result = @{$self->{param}{$name}};

		if ($PARAM_UTF8) {
		  eval "require Encode; 1;" unless Encode->can('decode'); # bring in these functions
		  @result = map {ref $_ ? $_ : $self->_decode_utf8($_) } @result;
		}

		return wantarray ?  @result : $result[0];
	}
1;