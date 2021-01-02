module model

const (
	banned_names          = ['NotNite']
	supported_vcs_systems = ['git', 'hg']
	max_name_len = 10
)

pub struct Mod {
pub:
	id           int
	// TODO currently, "name" holds both the username and the module name, doesn't sound very future proof
	name         string
	url          string
	nr_downloads int
	vcs          string = 'git'
}

fn is_valid_mod_name(s string) bool {
	if s.len > max_name_len || s.len < 2 {
		return false
	}
	for c in s {
		if !(c.is_digit() || c.is_letter() || c == `.`) {
			return false
		}
	}
	return true
}

pub fn new_mod(opts Mod) ?Mod {
	user_name := opts.name.all_before('.')
	mod_name := opts.name.all_after('.').to_lower()
	if is_valid_mod_name(mod_name) {
		return error('not valid mod name "$opts.name"')
	}
	for banned_name in banned_names {
		if banned_name in mod_name {
			return error('invalid name $opts.name')
		}
	}
	url := opts.url.replace('<', '&lt;')
	if ' ' in url || '%' in url {
		return error('invalid url "$opts.url"')
	}
	if !url.starts_with('github.com/') && !url.starts_with('http://github.com/') && !url.starts_with('https://github.com/') {
		return error('url must belong to GitHub "$opts.url"')
	}
	mut vcs := opts.vcs.to_lower()
	if vcs == '' {
		vcs = 'git'
	} else if vcs !in supported_vcs_systems {
		return error('unsupported vcs "$opts.vcs"')
	}
	return Mod{
		id: opts.id
		name: '${user_name}.$mod_name'
		url: url
		nr_downloads: opts.nr_downloads
		vcs: vcs
	}
}
