extends Node

const DISALLOWED_TLDS = [
	'.local',
	'.arpa',
	'.invalid',
	'.localhost',
	'.internal',
	'.example',
	'.alt',
	'.onion'
];

const MAX_HANDLE_LENGTH = 252;

var current_did: String;

func resolve_identity_from_handle(handle: String): ## Resolve an identity from a handle
	print("Resolving handle: " + handle);
	var did = await find_did_from_handle(handle);
	print("DID: ", did);

func find_did_from_handle(handle: String) -> String: ## Check well-knowns and text records to resolve a DID from a handle
	var did: String = "N/A";

	# try well known
	# todo: also check wellknown files (wellknown should always be checked first)
	
	# try txt record
	did = await resolve_txt_record(handle);
	
	return did;

func resolve_txt_record(handle: String) -> String:
	var http_request: HTTPRequest = AwaitableHTTPRequest.new();
	add_child(http_request);
	
	http_request.connect("request_completed", Callable(self, "txt_request_return"));
	
	var url = "https://dns.google/resolve?name=_atproto." + handle + "&type=TXT";
	var headers = ["Accept: application/dns-json"];
	var request = await http_request.request(url, headers);
	
	return current_did;

func txt_request_return(result, response_code, headers, body) -> String:
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8());
		if json and "Answer" in json:
			for answer in json["Answer"]:
				if answer["type"] == 16: 
					print("TXT Record:", answer["data"]);
					current_did = answer["data"];
					return current_did;
	current_did = "";
	return "";
