use strict;
use warnings;

use Module::Build;

# -----------------------------------------------

my $class = Module::Build->subclass(code => <<'EOF');

sub ACTION_authortest
{
	my($self) = @_;

	$self->depends_on('build');
	$self->depends_on('manifest');
	$self->depends_on('distmeta');

	$self->test_files( qw< t xt/author > );
	$self->recursive_test_files(1);

	$self->depends_on('test');

	return;
}
EOF

$class -> new
(
	module_name    => 'Data::RenderAsTree',
	license        => 'artistic_2',
	dist_abstract  => 'Render any data structure as an object of type Tree::DAG_Node',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		'Test::More' => 1.001014,
		'Test::Pod' => 1.48,
	},
	configure_requires =>
	{
		'Module::Build' => 0.4211,
	},
	meta_merge =>
	{
		resources =>
		{
			repository => 'https://github.com/ronsavage/Data-RenderAsTree',
		},
	},
	requires =>
	{
		'Data::Dumper::Concise' => 2.022,
		'File::Slurp' => 9999.19,
		'File::Spec' => 0,
		'Moo' => 1.007000,
		'Scalar::Util' => 1.41,
		'Set::Array' => 0.30,
		'strict' => 0,
		'Text::Truncate' => '1.06',
		'Tree::DAG_Node' => 1.24,
		'Types::Standard' => 1.000005,
		'warnings' => 0,
	},
	resources =>
	{
		'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Data-RenderAsTree',
		'license' => 'http://opensource.org/licenses/Artistic-2.0',
	},
) -> create_build_script();
