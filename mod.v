module main

fn clean_url(s string) string {
	return s.replace(' ', '-').to_lower()
}
