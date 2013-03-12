#!/usr/bin/perl
# registro.br - Epp.pm              
#
# Controller - www.Is4web.com.br
# 2005 - 2013
#Código aberto
#Direitos: is4web.com Sistemas
#Use-o por conta e risco

package RegistroBR::Epp;

require 5.004;
require Exporter;
#use strict;
use Net::EPP::Client;
use Carp;
use Data::Dumper;
use XML::Simple;
#use CGI::Carp qw(fatalsToBrowser);

use vars qw(@ISA $VERSION $DEBUG $ERR $ERR2 $dir);

#set current dir
$dir = __FILE__;
$dir =~ s/Epp\.pm//;

@ISA = qw(Exporter);
$VERSION = '1.0';

sub new {
	my @chars =  (0 .. 9);
	my $id = "CONTROLLER_".$chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)];
	my $self = { 
		'sysid' => $id,
		'timeout' => 60,
		'ERR' => ''
	};

	bless ($self);

	return ($self);
}

sub connect {
	my ($self) = @_;

	my $handle = Net::EPP::Client->new(
				host    => $self->{host},
				port    => $self->{port}, 
				ssl     => 1,
				dom  => 1,
				);

    if (my $greeting = $handle->connect(
					SSL_version => 'tlsv1',
					SSL_use_cert => 1,
					SSL_verify_mode => '0x00',
					SSL_cert_file => $dir.'../certificados/client.pem',
					SSL_key_file => $dir.'../certificados/client.pem',
					SSL_passwd_cb =>  sub { return $self->{certpass} }
					)) { 
		#check greeting
		warn "Connected to $self->{host}:$self->{port}\n Response: ".$greeting->toString(1)."\n" if $DEBUG;
	} else {
		warn "Could not connect\nError: &IO::Socket::SSL::errstr\n" if $DEBUG;;
		$self->{'ERR'} .= &IO::Socket::SSL::errstr; die; 	
	}

	#return connection
	return ($handle);
}

sub login {
	local ($self,$handle,$newpw,$lang) = @_;
	local $response;

	#set vars
	local $values = { 
		%$self,
		newpass => $newpw,
		lang => $lang,
	};

	#send command
	command("login");

	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
	if ($result->getAttribute('code') == 1000) {
		warn "Login success\n".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		#get envirionment
		#set Global vars
		return ($handle);
	} else { 
		warn "Login failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$ERR2====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg");
		return ();
	}
}

sub hello {
	local ($self,$handle) = @_;
	local $response;

	#set vars
	local $values = { %$self, };
	
	#send command
	command("hello");
	
	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","greeting"))[0];
	if ($result) {
		warn "Hello success\n".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle);
	} else { 
		warn "Hello failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return;
	}
}	

sub logout {
	local ($self,$handle) = @_;
	local $response;

	#set vars
	local $values = { %$self,};

	#send command
	command("logout");
	
	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1500) {
		warn "Logout success\n".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle);
    } else { 
		warn "Logout failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return;
	}
}

sub disconnect {
	local ($self,$handle) = @_;
	$self = 0;
	$handle->disconnect;
	return;
}

####################
#Comandos de Contato
####################
sub contact_create {
	local ($self,$handle,$name,$addr,$addrn,$addrc,$city,$sp,$pc,$cc,$voice,$voicer,$email,$pw) = @_;
	local $response;

	#hash destroy contact
	foreach (keys %$values) {
		delete $values->{$_} if /^contact/i;
	}

	#format vars
	my $id = uc $name; $id =~ s/(.).+?( |$)/$1/g; #pegar iniciais
	$voicer = " " if !$voicer;
	#set vars
	local $values = { 
		%$self, #hash acumulutativo , hash concatenate , hash add()
		contact_id => $id,
		contact_name => $name,
		contact_addr => $addr,
		contact_addrn => $addrn,
		contact_addrc => $addrc,
		contact_city => $city,
		contact_sp => $sp,
		contact_pc => $pc,
		contact_cc => $cc,
		contact_voice => $voice,
		contact_voicer => $voicer,
		contact_email => $email,
		contact_pw => $pw
	};


	#send command
	command("contact_create");

	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
	if ($result->getAttribute('code') == 1000) {
		warn "Create contact success\n".$response->toString(2) if $DEBUG;
		$result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","resData"))[0];
		$result = ($result->getChildrenByTagName("contact:creData"))[0];
		$id = $result->findvalue("contact:id");
		warn "Contact_id = $id\n" if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle,$id);
	} else { 
		warn "Create contact failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return;
	}
}

sub contact_check {
	local ($self,$handle,$id) = @_;
	local $response;

	#format vars
	$id = uc $id;
	#set vars
	local $values = { 
		%$self,
		contact_id => $id, 
	};

	#send command
	command("contact_check");
	
	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1000) {
		warn "Contact check success\n".$response->toString(2) if $DEBUG;
		$result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","resData"))[0];
		warn "a $result" if $DEBUG;
		$result = ($result->getChildrenByTagName("contact:chkData"))[0];
		warn "b $result" if $DEBUG;
		$result = ($result->getChildrenByTagName("contact:cd"))[0];
		warn "c $result" if $DEBUG;
		$result = $result->getChildNodes("contact:id");
		warn "d $result" if $DEBUG;
		$free = $result->[0]->getAttribute('avail');
		warn "Avail $free" if $DEBUG;;
		$reason = $result->[1]->textContent("contact:reason") if !$free;
		warn "Reason: $reason" if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle,$free,$reason);
    } else { 
		warn "Contact check failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg");
		return;
	}
}

sub contact_info {
	local ($self,$handle,$id) = @_;
	local $response;

	#format vars
	$id = uc $id;
	#set vars
	local $values = { 
		%$self,
		contact_id => $id, 
	};

	#send command
	command("contact_info");
	
	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1000) {
		$result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","resData"))[0];
		$result = ($result->getChildrenByTagName("contact:infData"))[0];
		my $res = XML::Simple::XMLin($result->toString(0));
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;

		return ($handle,$res);
#	} elsif ($result->getAttribute('code') == 2303) {
#		warn "Contact info success\n".$response->toString(2) if $DEBUG;
#		#avail
#		return ($handle,1);
    } else { 
		warn "Contact info failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return;
	}
}

sub contact_update {
	local ($self,$handle,$id,$name,$addr,$addrn,$addrc,$city,$sp,$pc,$cc,$voice,$voicer,$email) = @_;
	local $response;

	#hash destroy contact
	foreach (keys %$values) {
		delete $values->{$_} if /^contact/i;
	}

	#format vars
	$id = uc $id;
	$voicer = " " if !$voicer;
	#set vars
	local $values = { 
		%$self, 
		contact_id => $id,
		contact_name => $name,
		contact_addr => $addr,
		contact_addrn => $addrn,
		contact_addrc => $addrc,
		contact_city => $city,
		contact_sp => $sp,
		contact_pc => $pc,
		contact_cc => $cc,
		contact_voice => $voice,
		contact_voicer => $voicer,
		contact_email => $email	
	};

	#send command
	command("contact_update");

	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1000) {
		warn "Contact update success\n".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle);
	} else { 
		warn "Contact update failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return;
	}
}

sub contact_delete {
	local ($self,$handle,$id) = @_;
	local $response;

	#hash destroy contact
	foreach (keys %$values) {
		delete $values->{$_} if /^contact/i;
	}

	#format vars
	$id = uc $id;
	#set vars
	local $values = { 
		%$self,
		contact_id => $id,
	};

	#send command
	command("contact_delete");

	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1000) {
		warn "Contact delete success\n".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle);
	} else { 
		warn "Contact delete failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return;
	}
}


#########################
#Comandos de Organização
#########################
sub org_check {
	local ($self,$handle,$id) = @_;
	local $response;

	#set vars
	local $values = { 
		%$self,
		org_id => $id,
	};

	#send command
	command("org_check");
	
	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1000) {
		warn "Org check success\n".$response->toString(2) if $DEBUG;
		$result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","resData"))[0];
		warn "a $result" if $DEBUG;
		$result = ($result->getChildrenByTagName("contact:chkData"))[0];
		warn "b $result" if $DEBUG;
		$result = ($result->getChildrenByTagName("contact:cd"))[0];
		warn "c $result" if $DEBUG;
		$result = $result->getChildNodes("contact:id");
		warn "d $result" if $DEBUG;
		$free = $result->[0]->getAttribute('avail');
		warn "Avail $free" if $DEBUG;;
		$reason = $result->[1]->textContent("contact:reason") if !$free;
		warn "Reason: $reason" if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle,$free,$reason);
    } else { 
		warn "Org check failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return;
	}
}

sub org_create {
	local ($self,$handle,$id,$cid,$resp,$name,$addr,$addrn,$addrc,$city,$sp,$pc,$cc,$voice,$voicer,$email) = @_;
	local $response;

	#hash destroy org
	delete $values->{contact_id};
	delete $values->{contact_name};
	foreach (keys %$values) {
		delete $values->{$_} if /^org/i;
	}
	
	#format vars
	$cid = uc $cid;
	$voicer = " " if !$voicer;
	#set vars
	local $values = { 
		%$self, #hash acumulutativo , hash concatenate , hash add()
		contact_id => $cid,
		contact_name => $resp,
		org_id => $id,
		org_name => $name,
		org_addr => $addr,
		org_addrn => $addrn,
		org_addrc => $addrc,
		org_city => $city,
		org_sp => $sp,
		org_pc => $pc,
		org_cc => $cc,
		org_voice => $voice,
		org_voicer => $voicer,
		org_email => $email	
	};

	#send command
	command("org_create");

	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1001) {
		warn "Create org success\n".$response->toString(2) if $DEBUG;
		warn "Org_id = $id\n" if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle,$id);
    } else { 
		warn "Create org failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return;
	}
}

sub org_info {
	local ($self,$handle,$id) = @_;
	local $response;

	#set vars
	local $values = { 
		%$self,
		org_id => $id,
	};

	#send command
	command("org_info");
	
	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1000) {
		$result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","resData"))[0];
		$result = ($result->getChildrenByTagName("contact:infData"))[0];
		my $res = XML::Simple::XMLin($result->toString(0));

		$result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","extension"))[0];
		$result = ($result->getChildrenByTagName("brorg:infData"))[0];
		my $ext = XML::Simple::XMLin($result->toString(0));
#die $result->toString(0);
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle,$res,$ext);
	} elsif ($result->getAttribute('code') == 2303) {
		warn "Org info success\n".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		#avail
		return ($handle,1);
    } else { 
		warn "Org info failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return;
	}
}

sub org_update {
	local ($self,$handle,$id,$cid,$cid_r,$resp,$name,$addr,$addrn,$addrc,$city,$sp,$pc,$cc,$voice,$voicer,$email) = @_;
	local $response;

	#hash destroy contact
	foreach (keys %$values) {
		delete $values->{$_} if /^contact/i;
		delete $values->{$_} if /^org/i;
	}
	
	#check data
	$values->{add1} = " " if ($cid && $cid ne "" && $cid_r ne "");
	$values->{rm1} = " " if ($resp && $resp ne "");
	$voicer = " " if !$voicer;

	#format vars
	$cid = uc $cid;
	$cid_r = uc $cid_r;
	#set vars
	local $values = { 
		%$self,
		org_id => $id,
		contact_id => $cid,
		contact_id_r => $cid_r,
		contact_name => $resp,
		org_name => $name,
		org_addr => $addr,
		org_addrn => $addrn,
		org_addrc => $addrc,
		org_city => $city,
		org_sp => $sp,
		org_pc => $pc,
		org_cc => $cc,
		org_voice => $voice,
		org_voicer => $voicer,
		org_email => $email	
	};

	#send command
	command("org_update");

	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1000) {
		warn "Contact update success\n".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle,1);
    } elsif ($result->getAttribute('code') == 1001) {
		warn "Contact update success - Pending\n".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle,2);
	} else { 
		warn "Contact update failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); 
		return (0,$handle); ########qd for erro retorna na segunda posicao pra so poder reutilizar se souber
	}
}

#####################
#Comandos de Domínio
#####################

sub domain_check {
	local ($self,$handle,$domain,$cnpj) = @_;
	local $response;

	#set vars
	local $values = { 
		%$self,
		domain_name => $domain,
	};
	$values->{org_id} = $cnpj unless $domain;


	#send command
	command("domain_check");
	
	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1000) {
		warn "Domain check success\n".$response->toString(2) if $DEBUG;
		$result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","resData"))[0];
		warn "a $result" if $DEBUG;
		$result = ($result->getChildrenByTagName("domain:chkData"))[0];
		warn "b $result" if $DEBUG;
		$result = ($result->getChildrenByTagName("domain:cd"))[0];
		warn "c $result" if $DEBUG;
		$result = $result->getChildNodes("domain:name");
		warn "d $result" if $DEBUG;
		$free = $result->[0]->getAttribute('avail');
		warn "Avail $free" if $DEBUG;;
		$reason = $result->[1]->textContent("domain:reason") if !$free;
		warn "Reason: $reason" if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		my $ext = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","extension"))[0];
		$ext = ($ext->getChildrenByTagName("brdomain:chkData"))[0] if $ext;
		$ext = ($ext->getChildrenByTagName("brdomain:cd"))[0] if $ext;
		my $status = $free;
		$status = 2 if $ext and $ext->getAttribute('hasConcurrent') == 1; #2 => Existe ticket concorrente
		return ($handle,$status,$reason);
    } else { 
		warn "Domain check failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return;
	}
}

sub domain_create {
	local ($self,$handle,$domain,$cnpj,$renew,$ns1,$ip1v4,$ip1v6,$ns2,$ip2v4,$ip2v6,
			 $ns3,$ip3v4,$ip3v6,$ns4,$ip4v4,$ip4v6,$ns5,$ip5v4,$ip5v6) = @_;
	local $response;

	#hash destroy domain
	delete $values->{org_id};
	delete $values->{auto_renew};
	foreach (keys %$values) {
		delete $values->{$_} if /^domain/i;
	}
	
	#set vars
	local $values = { 
		%$self, #hash acumulutativo , hash concatenate , hash add()
		org_id => $cnpj,
		domain_name => $domain,
		auto_renew => $renew,
		domain_ns1 => $ns1,
		domain_ip1v4 => $ip1v4,
		domain_ip1v6 => $ip1v6,
		domain_ns2 => $ns2,
		domain_ip2v4 => $ip2v4,
		domain_ip2v6 => $ip2v6,
		domain_ns3 => $ns3,
		domain_ip3v4 => $ip3v4,
		domain_ip3v6 => $ip3v6,
		domain_ns4 => $ns4,
		domain_ip4v4 => $ip4v4,
		domain_ip4v6 => $ip4v6,
		domain_ns5 => $ns5,
		domain_ip5v4 => $ip5v4,
		domain_ip5v6 => $ip5v6,
		domain_unit => $self->{period_unit},
		domain_period => $self->{period},
	};

	#send command
	command("domain_create");

	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1001) {
		warn "Domain create success\n".$response->toString(2) if $DEBUG;
		$result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","extension"))[0];
		warn "a $result" if $DEBUG;
		$result = ($result->getChildrenByTagName("brdomain:creData"))[0];
		warn "b $result" if $DEBUG;
	 my $ticket = $result->findvalue("brdomain:ticketNumber");
		warn "c $ticket" if $DEBUG;
		$result = $result->getChildrenByTagName("brdomain:pending");
		warn "d $result" if $DEBUG;
#		foreach ($result->getChildNodes("brdomain:doc")) {
#			$reason .= $_->getAttribute('status');
#			$reason .= $_->getChildrenByTagName('brdomain:description');
#			warn "Doc $reason" if $DEBUG;
#		}
#		foreach ($result->getChildNodes("brdomain:dns")) {
#			$reason .= $_->getAttribute('status');
#			$reason .= $_->getChildrenByTagName('brdomain:hostName');
#			$reason = $result->[1]->textContent("domain:reason");
#			warn "Reason: $reason" if $DEBUG;
#		}
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle,$ticket,$reason);
    } else { 
		warn "Domain create failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return();
	}
}

sub domain_info {
	local ($self,$handle,$domain,$ticket) = @_;
	local $response;
	
	#set vars
	local $values = { 
		%$self,
		ticket_id => $ticket,
		domain_name => $domain,
	};

	#send command
	command("domain_info");
	
	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1000) {
		warn "Domain info success\n".$response->toString(2) if $DEBUG;
		$result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","resData"))[0];
		warn "a $result" if $DEBUG;
		$result = ($result->getChildrenByTagName("domain:infData"))[0];
		warn "b $result" if $DEBUG;
#	  my $exDate = $result->findvalue("domain:exDate");
#		$exDate =~ s/(....\-..?\-..?).*/$1/;
#		warn "c $exDate" if $DEBUG;


		my $res = XML::Simple::XMLin($result->toString(0));
#		die Dumper($res);
#die $res->{'xmlns:domain'};

		$result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","extension"))[0];
		warn "a $result" if $DEBUG;
		$result = ($result->getChildrenByTagName("brdomain:infData"))[0];
		warn "b $result" if $DEBUG;
#		$result = $result->getChildNodes("brdomain:pending");
#		warn "c $result" if $DEBUG;
#	  my $pending = 1 if $result;
		my $ext = XML::Simple::XMLin($result->toString(0));
#		$ext = Dumper($ext);
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		
		return ($handle,$res,$ext);
	} elsif ($result->getAttribute('code') == 2303) {
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
    	return 0; #Não existe		
    } else { 
		warn "Domain info failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return;
	}
}

sub domain_update {
	local ($self,$handle,$domain,$ticket,$renew,$tech,$admin,$bill,$stats,$s_desc,$ns1,$ip1v4,$ip1v6,$ns2,$ip2v4,$ip2v6,
			$ns3,$ip3v4,$ip3v6,$ns4,$ip4v4,$ip4v6,$ns5,$ip5v4,$ip5v6,
			$tech_r,$admin_r,$bill_r,$stats_r,$s_desc_r,$ns1_r,$ip1v4_r,$ip1v6_r,$ns2_r,$ip2v4_r,$ip2v6_r,
			$ns3_r,$ip3v4_r,$ip3v6_r,$ns4_r,$ip4v4_r,$ip4v6_r,$ns5_r,$ip5v4_r,$ip5v6_r) = @_;
	local $response;

	#hash destroy domain
	delete $values->{ticket_id};
	delete $values->{auto_renew};
	foreach (keys %$values) {
		delete $values->{$_} if /^domain|^add|^rm|^ns|^chg/i;
	}

	#set vars
	local $values = { 
		%$self, #hash acumulutativo , hash concatenate , hash add()
		ticket_id => $ticket,
		auto_renew => $renew,
		domain_name => $domain,
		domain_tech => $tech,
		domain_admin => $admin,
		domain_billing => $bill,
		domain_status => $stats,
		domain_status_desc => $s_desc,
		domain_ns1 => $ns1,
		domain_ip1v4 => $ip1v4,
		domain_ip1v6 => $ip1v6,
		domain_ns2 => $ns2,
		domain_ip2v4 => $ip2v4,
		domain_ip2v6 => $ip2v6,
		domain_ns3 => $ns3,
		domain_ip3v4 => $ip3v4,
		domain_ip3v6 => $ip3v6,
		domain_ns4 => $ns4,
		domain_ip4v4 => $ip4v4,
		domain_ip4v6 => $ip4v6,
		domain_ns5 => $ns5,
		domain_ip5v4 => $ip5v4,
		domain_ip5v6 => $ip5v6,
		domain_tech_r => $tech_r,
		domain_admin_r => $admin_r,
		domain_billing_r => $bill_r,
		domain_status_r => $stats_r,
		domain_status_desc_r => $s_desc_r,
		domain_ns1_r => $ns1_r,
		domain_ip1v4_r => $ip1v4_r,
		domain_ip1v6_r => $ip1v6_r,
		domain_ns2_r => $ns2_r,
		domain_ip2v4_r => $ip2v4_r,
		domain_ip2v6_r => $ip2v6_r,
		domain_ns3_r => $ns3_r,
		domain_ip3v4_r => $ip3v4_r,
		domain_ip3v6_r => $ip3v6_r,
		domain_ns4_r => $ns4_r,
		domain_ip4v4_r => $ip4v4_r,
		domain_ip4v6_r => $ip4v6_r,
		domain_ns5_r => $ns5_r,
		domain_ip5v4_r => $ip5v4_r,
		domain_ip5v6_r => $ip5v6_r,
	}; 

	#send command
	command("domain_update");	

	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1000) {
		warn "Domain update success\n".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle,1);
    } else { 
		warn "Domain update failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return 0;
	}
}

sub domain_renew {
	local ($self,$handle,$domain,$date,$period,$unit) = @_;
	local $response;

	#hash destroy domain
	delete $values->{renew_unit};
	delete $values->{renew_period};
	foreach (keys %$values) {
		delete $values->{$_} if /^domain/i;
	}

	#set vars
	local $values = { 
		%$self,
		domain_exp => $date,
		domain_name => $domain,
		renew_unit => $unit,
		renew_period => $period,
	};

	#send command
	command("domain_renew");
	warn "Resposta do EPP:".$response->toString(2) if $DEBUG;
	
	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1000) {
		warn "Domain Renew success\n".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle);
    } else { 
		warn "Domain Renew failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg");
		#reutilizar para homologar
		return ("ERROR",$handle);
	}
}


#####################
#Comandos de Poll
#####################
sub poll {
	local ($self,$handle,$opt,$msgid) = @_;
	local $response;

	#set vars
	local $values = { 
		%$self,
		poll_id => $msgid,
		poll_opt => $opt,
	};

	#send command
	command("poll");
	
	#check sucessfull
	my $result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","result"))[0];
    if ($result->getAttribute('code') == 1301) {
		warn "Poll $opt success\n".$response->toString(2) if $DEBUG;
		$result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","msgQ"))[0];
	 my $count = $result->getAttribute('count');
		warn "b $count" if $DEBUG;
	 my $id = $result->getAttribute('id');
		warn "c $id" if $DEBUG;
		$result = ($result->getElementsByTagName("msg"))[0];
		my %res;
		foreach my $node ($result->getChildrenByTagName("*")) {
			my $value = $node->textContent; $value =~ s/\n/ /g;
			$res{ $node->localname } = trim($value);
		}

		if ($result = ($response->getElementsByTagNameNS("urn:ietf:params:xml:ns:epp-1.0","extension"))[0]) { #acrescentar na mensagem
			$result = ($result->getChildrenByLocalName("panData"))[0];
			foreach my $node ( $result->getChildrenByTagName("*") ) {
				my $value = $node->textContent; $value =~ s/\n/ /g;
				$res{ $node->localname } = trim($value);
			}
		}		
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle,$id,\%res);
	} elsif ($result->getAttribute('code') == 1300) {
		warn "Poll $opt success\n".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle,-1,"No messages"); #no messages
	}  elsif ($result->getAttribute('code') == 1000) {
		warn "Poll $opt success\n".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG == 3;
		return ($handle,'',''); #no messages
    } else { 
		warn "Poll $opt failed: ".$response->toString(2) if $DEBUG;
		$self->{'ERR'} .= "===command:$self->{'ERR2'}====\n====response:".$response->toString(2)."======\n" if $DEBUG >= 2;
		$self->{'ERR'} .= $result->textContent("msg"); return;
	}
} 


#####################
#Subs
#####################
sub command {
	my $file = $dir.shift().".xml";
	my $cmd;

	#make commands
	unless (-e $file) {
		die "Command file not found\n";
	} else {
		open COMMAND, $file;
		while (<COMMAND>) {
			next if /^\#/;
			m/^/; #clear $#
			s/\{(\S+?)\}/$values->{$1}/gi;
			next if $1 && $values->{$1} eq "";
			$cmd .= $_;	
		}
		#Remove empty tags
		1 while $cmd =~ s/\<(\S+?)\>\s*?\<\/\1\>//gs; #empty
		$cmd =~ s/^\s*$//mg; #empty lines
		$cmd =~ s/\n\n/\n/sg; #duplicate enter

#		warn "$cmd\n";
		$self->{ERR2} .= "$cmd" if $DEBUG;
		close COMMAND;

		$handle->send_frame($cmd);

		eval {
			local $SIG{ALRM} = sub { die "alarm\n" };
			alarm($timeout);
			$response = $handle->get_frame();
			alarm(0);
		};
	}
}

sub trim($) {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub DESTROY
{
        my ($self,$handle) = @_;
		$self = 0;
		$handle->disconnect if $handle;
}

1;