package OpenNMS::Config::Git::Change;

use strict;
use warnings;
use Carp;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {
		FILE => shift,
		GIT  => shift,
	};

	if (not defined $self->{GIT}) {
		croak "You must specify a file and Git object when creating a $class object!";
	}

	bless($self, $class);
	return $self;
}

sub _git {
	my $self = shift;
	return $self->{GIT};
}

sub file {
	my $self = shift;
	return $self->{FILE};
}

sub exec {
	croak "You must implement the exec method in your subclass!"
}

package OpenNMS::Config::Git::Add;

use strict;
use warnings;
use base qw(OpenNMS::Config::Git::Change);

sub exec {
	my $self = shift;
	$self->_git()->add($self->file());
}

package OpenNMS::Config::Git::Remove;

use strict;
use warnings;
use base qw(OpenNMS::Config::Git::Change);

sub exec {
	my $self = shift;
	$self->_git()->rm($self->file());
}

package OpenNMS::Config::Git;

use 5.008008;
use strict;
use warnings;

use Carp;
use File::Path;
use File::Spec;
use Git;
use List::MoreUtils qw(apply);

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.1.0';

=head1 NAME

OpenNMS::Config::Git - OpenNMS git manipulation.

=head1 SYNOPSIS

  use OpenNMS::Config::Git;

=head1 DESCRIPTION

This module is for interacting with an OpenNMS git
directory.

=head1 CONSTRUCTOR

OpenNMS::Config::Git->new($gitroot)

Given a directory, create a Git object.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $dir = shift;
	if (not defined $dir) {
		carp "You must pass the git directory!";
	}

	my $self = {
		DIR => $dir,
	};

	bless($self, $class);
	return $self;
}

=head1 METHODS

=cut

sub _git {
	my $self = shift;

	if (exists $self->{GIT}) {
		return $self->{GIT};
	}

	if (-d $self->dir() and -d File::Spec->catdir($self->dir(), ".git")) {
		$self->{GIT} = Git->repository(Directory => $self->dir());
		return $self->{GIT};
	}

	return undef;
}

=head2 * dir

The directory of this git repository.

=cut

sub dir {
	my $self = shift;
	return $self->{DIR};
}

=head2 * init(%options)

Initialize the git repository.

Options:

=over 2

=item * branch_name

The name of the initial branch.  (Default: master)

=back

=cut

sub init {
	my $self = shift;
	my %options = @_;

	if (! -d $self->dir()) {
		mkpath($self->dir());
	}

	git_cmd_try {
		Git::command_oneline('init', $self->dir());
	} "Error \%d while initializing " . $self->dir() . " as a git repository: \%s";

	if (exists $options{'branch_name'}) {
		git_cmd_try {
			$self->_git()->command_oneline('symbolic-ref', 'HEAD', 'refs/heads/' . $options{'branch_name'});
		} "Error \%d while setting initial branch name to $options{'branch_name'}: \%s";
	}

	return $self;
}

=head2 * author([$author_field])

Returns the author used when committing changes to the git repository.
If an argument is specified, the author is set.

=cut

sub author {
	my $self = shift;
	my $author = shift;
	if (defined $author) {
		$self->{AUTHOR} = $author;
	}
	return $self->{AUTHOR};
}

=head2 * get_branch_name()

Get the name of the current branch.

=cut

sub get_branch_name {
	my $self = shift;
	
	my $branch = undef;
	git_cmd_try {
		$branch = $self->_git()->command_oneline('symbolic-ref', 'HEAD');
		$branch =~ s,^refs/heads/,,;
	} "Error \%d while running 'git branch': \%s";

	return $branch;
}

=head2 * get_index_status($filename)

Get the status of the given file in the index.

Valid responses are: unchanged, untracked, new, modified, deleted

=cut

our $STATES = {
	' '   => 'unchanged',
	'?'   => 'untracked',
	'A'   => 'new',
	'M'   => 'modified',
	'D'   => 'deleted',
};

sub get_index_status {
	my $self = shift;
	my $file = shift;

	my $status = ' ';
	git_cmd_try {
		my @ret = $self->_git()->command('status', '--porcelain', $file);
		if (@ret == 1) {
			$status = $ret[0];
			$status =~ s/^(.).*$/$1/;
		}
	} "Error \%d while running git status on $file: \%s";

	return $STATES->{$status};
}

=head2 * get_modifications()

Get a list of OpenNMS::Config::Git::Change objects representing all
modified files in the working tree.

=cut

sub get_modifications {
	my $self = shift;
	
	my @entries;
	git_cmd_try {
		@entries = $self->_git()->command('status', '--porcelain');
	} "Error \%d while running git status on the working tree: \%s";

	my @results;
	for my $entry (@entries) {
		if ($entry =~ /^(.)(.) (.*)$/) {
			my ($index, $working, $filename) = ($1, $2, $3);
			if ($working eq 'D') {
				push(@results, OpenNMS::Config::Git::Remove->new($filename, $self));
			} else {
				push(@results, OpenNMS::Config::Git::Add->new($filename, $self));
			}
		} else {
			print STDERR "unable to parse $entry\n";
		}
	}
	return sort { $a->file() cmp $b->file() } @results;
}

=head2 * add(@files_and_directories)

Add one or more files or directories to the git repository.

=cut

sub add {
	my $self = shift;
	
	my @files = @_;
	
	git_cmd_try {
		$self->_git()->command('add', @files);
	} "Error \%d while adding " . scalar(@files) . " files or directories: \%s";

	return $self;
}

=head2 * rm($file)

Given a file, remove it from the git index.

=cut

sub rm {
	my $self = shift;
	my $file = shift;
	
	if (not defined $file) {
		croak "You must specify a file to remove!";
	}
	
	git_cmd_try {
		$self->_git()->command('rm', $file);
	} "Error \%d while removing $file from the git index: \%s";

	return $self;
}

=head2 * commit($commit_message)

Given a commit message, commit the currently staged files to the git repository.

=cut

sub commit {
	my $self = shift;
	my $message = shift;
	
	if (not defined $message) {
		croak "You must specify a commit message!";
	}

	my @extra_args;
	if (defined $self->author()) {
		push(@extra_args, '--author=' . $self->author());
	}

	git_cmd_try {
		$self->_git()->command('commit', '-m', $message, @extra_args);
	} "Error \%d while committing staged files to the git repository: \%s";
	
	return $self;
}

=head2 * create_branch($new_branch_name, $existing_branch)

Given a new branch name, and an existing branch name, create a new branch
based on the existing branch.

=cut

sub create_branch {
	my $self = shift;
	my $to   = shift;
	my $from = shift;
	
	if (not defined $from or not defined $to) {
		croak "You must specify a branch name, and a source branch name!";
	}
	
	git_cmd_try {
		$self->_git()->command('branch', $to, $from);
	} "Error \%d while attempting to create the '$to' branch from the '$from' branch: \%s";

	return $self;
}

=head2 * checkout($branch_name)

Check out the branch with the given name.

=cut

sub checkout {
	my $self = shift;
	my $branch = shift;
	
	if (not defined $branch) {
		croak "You must specify a branch name!";
	}

	git_cmd_try {
		$self->_git()->command('checkout', $branch);
	} "Error \%d while checking out the '$branch' branch: \%s";

	return $self;
}

=head2 * merge($branch_name)

Merge the given branch into the current branch.

=cut

sub merge {
	my $self = shift;
	my $branch = shift;
	
	if (not defined $branch) {
		croak "You must specify a branch to merge!";
	}

	git_cmd_try {
		$self->_git()->command('merge', $branch);
	} "Error \%d while merging the '$branch' branch into the current branch: \%s";

	return $self;
}

=head2 * tag($tag_name)

Create a tag with the given name.

=cut

sub tag {
	my $self = shift;
	my $tag  = shift;
	
	if (not defined $tag) {
		croak "You must specify a tag name!";
	}
	
	git_cmd_try {
		$self->_git()->command('tag', $tag);
	} "Error \%d while creating the '$tag' tag: \%s";

	return $self;
}


1;
__END__

=head1 AUTHOR

Benjamin Reed E<lt>ranger@opennms.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by The OpenNMS Group, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
