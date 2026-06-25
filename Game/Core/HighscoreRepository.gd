extends Node

# Supabase project credentials (publishable key is safe to ship in client)
const SUPABASE_URL := "https://uawkvvgwaewztsafspab.supabase.co"
const SUPABASE_KEY := "sb_publishable_EYHTKKBb2rjlnNjqK8CEqw_0CZbxUk4"

signal scores_fetched(scores: Array)
signal score_submitted(success: bool, message: String)

var _http_get: HTTPRequest
var _http_post: HTTPRequest

func _ready() -> void:
	# Must run while the game tree is paused (game over screen)
	process_mode = Node.PROCESS_MODE_ALWAYS

	_http_get = HTTPRequest.new()
	add_child(_http_get)
	_http_get.request_completed.connect(_on_get_completed)

	_http_post = HTTPRequest.new()
	add_child(_http_post)
	_http_post.request_completed.connect(_on_post_completed)

# Fetch top 10 scores, sorted by distance descending
func fetch_top_10() -> void:
	var url := SUPABASE_URL + "/rest/v1/highscores?select=name,distance,created_at&order=distance.desc&limit=10"
	var headers := PackedStringArray([
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY
	])
	_http_get.request(url, headers)

# Submit a score via the Edge Function (server validates + filters bad words)
func submit_score(player_name: String, distance: float, phase: int) -> void:
	var url := SUPABASE_URL + "/functions/v1/submit-score"
	var headers := PackedStringArray([
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
		"Content-Type: application/json"
	])
	var body := JSON.stringify({
		"name": player_name.to_upper(),
		"distance": distance,
		"phase": phase
	})
	_http_post.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_get_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		scores_fetched.emit(json if json != null else [])
	else:
		push_warning("HighscoreRepository: fetch failed, code %d" % response_code)
		scores_fetched.emit([])

func _on_post_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200 or response_code == 201:
		score_submitted.emit(true, "Score saved!")
	else:
		var json = JSON.parse_string(body.get_string_from_utf8())
		var msg := "Failed to save score."
		if json and json.has("error"):
			msg = json["error"]
		score_submitted.emit(false, msg)
