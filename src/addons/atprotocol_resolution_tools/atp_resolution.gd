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
	var identity = await fetch_did_info_from_plc(did);
	
	print(identity.handle, " found");

func find_did_from_handle(handle: String) -> String: ## Check well-knowns and text records to resolve a DID from a handle
	var did: String = "N/A";

	# try well known
	# todo: also check wellknown files (wellknown should always be checked first)
	
	# try txt record
	did = await resolve_txt_record(handle);
	
	did = did.erase(0, 4);
	
	return did;

func resolve_txt_record(handle: String) -> String:
	var url = "https://dns.google/resolve?name=_atproto." + handle + "&type=TXT";
	var headers = ["Accept: application/dns-json"];
	
	var request: HTTPRequest = AwaitableHTTPRequest.new();
	add_child(request);
	var resp = await request.async_request(url);
	
	
	if resp.success() and resp.status_ok():
		var json = JSON.new();
		json = resp.body_as_json();
		request.queue_free();
		
		if json and "Answer" in json:
			for answer in json["Answer"]:
				if answer["type"] == 16: 
					print("TXT Record:", answer["data"]);
					current_did = answer["data"];
					return current_did;
	return "";

func fetch_did_info_from_plc(did: String) -> ATPIdentity:
	var url = "https://plc.directory/" + did;
	
	var request: HTTPRequest = AwaitableHTTPRequest.new();
	add_child(request);
	var resp = await request.async_request(url);
	
	if resp.success() and resp.status_ok():
		var json = JSON.new();
		json = resp.body_as_json();
		request.queue_free();
		
		var identity = ATPIdentity.new();
		identity.service_id = json["service"][0]["id"];
		identity.service_type = json["service"][0]["type"];
		identity.service_endpoint = json["service"][0]["serviceEndpoint"];
		
		identity.id = json["id"];
		
		identity.handle = json["alsoKnownAs"][0]
		identity.handle = identity.handle.erase(0, 5);
		
		return identity;
	else:
		return null;
