#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Generate FNOL Demo Call — Rental Auto Insurance
# =============================================================================
# Uses macOS `say` + `ffmpeg` to produce a two-party insurance claims call.
# Agent voice: Samantha  |  Caller voice: Daniel
# Output: backend/assets/fnol_call.mp3
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="$(cd "$SCRIPT_DIR/../assets" && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

AGENT_VOICE="Samantha"
CALLER_VOICE="Daniel"
RATE=175
PAUSE_SHORT="$TMP_DIR/pause_short.aiff"
PAUSE_LONG="$TMP_DIR/pause_long.aiff"

# Generate silence gaps
ffmpeg -y -f lavfi -i anullsrc=r=22050:cl=mono -t 0.6 -acodec pcm_s16le "$PAUSE_SHORT" 2>/dev/null
ffmpeg -y -f lavfi -i anullsrc=r=22050:cl=mono -t 1.2 -acodec pcm_s16le "$PAUSE_LONG" 2>/dev/null

# Lines array: "VOICE|text"
LINES=(
  "$AGENT_VOICE|Thank you for calling National Rental Insurance claims department. My name is Karen. How can I help you today?"
  "$CALLER_VOICE|Hi Karen, my name is Marcus Johnson. I need to report a car accident. I was rear-ended about an hour ago."
  "$AGENT_VOICE|Oh no, I'm sorry to hear that Marcus. Are you and any passengers safe? Is anyone injured?"
  "$CALLER_VOICE|Yeah, I'm okay for the most part. No passengers. My neck is a little sore but nothing serious. I was able to walk away from it."
  "$AGENT_VOICE|I'm glad you're relatively okay. Let me pull up your account. Can you give me your policy number?"
  "$CALLER_VOICE|Sure, it's P O L dash 2026 dash 1001."
  "$AGENT_VOICE|Thank you. I have your account here, Marcus Johnson, premium tier policyholder. I can see you have an active rental agreement, A G R dash 2026 dash 101, for a Standard SUV. Is that the vehicle involved in the accident?"
  "$CALLER_VOICE|Yes, that's correct. The Standard SUV. I picked it up at Portland Airport on March 5th."
  "$AGENT_VOICE|Got it. Can you tell me what happened? Where and when did the accident occur?"
  "$CALLER_VOICE|I was stopped at the intersection of 5th and Main Street in downtown Portland. The light was red, and I was waiting to turn left. Then this guy behind me just plowed right into the back of my car. He ran the red light and hit me pretty hard."
  "$AGENT_VOICE|That sounds like a significant impact. Can you describe the damage to the vehicle?"
  "$CALLER_VOICE|The rear bumper is completely smashed in. The trunk is bent and won't close properly. Both tail lights are broken. And I think the rear axle might be damaged because the car was pulling to one side when I tried to move it. It's definitely not drivable."
  "$AGENT_VOICE|I understand. Did you get the other driver's information? Was a police report filed?"
  "$CALLER_VOICE|Yes, the police came and filed a report. The report number is P R dash 2026 dash 4521. The other driver was cited for running the red light. I got his insurance information too."
  "$AGENT_VOICE|Perfect, that's very helpful for our subrogation process. Now, since the vehicle is not drivable, we need to get you a replacement right away. As a premium tier policyholder, you're eligible for a complimentary upgrade on your replacement vehicle."
  "$CALLER_VOICE|Oh, that would be great. What are my options? I was hoping to maybe get something a bit nicer since this whole situation has been really stressful."
  "$AGENT_VOICE|Absolutely, I completely understand. Since you were in a Standard SUV, I can upgrade you to either a Premium SUV or a Luxury SUV at no additional cost. The Luxury SUV is our top tier, it has leather seats, premium sound system, and all the latest safety features."
  "$CALLER_VOICE|The Luxury SUV sounds perfect. I'll take that one. When can I pick it up?"
  "$AGENT_VOICE|I'll have the Luxury SUV ready for you at our Portland Airport location within two hours. I'm also going to arrange a tow for the damaged Standard SUV. Can you confirm the vehicle's current location?"
  "$CALLER_VOICE|It's still at the intersection of 5th and Main. The police had me pull it to the side of the road but it can't go anywhere."
  "$AGENT_VOICE|I'll dispatch a tow truck right away. Let me also note that since you mentioned neck soreness, I'd recommend getting checked out at an urgent care. Any medical expenses related to this accident would be covered under your policy's personal injury protection."
  "$CALLER_VOICE|Good to know. I'll definitely go get checked out. Is there anything else I need to do on my end?"
  "$AGENT_VOICE|I've filed claim number C L M dash 2026 dash 009 for you. You'll receive a confirmation email at marcus dot johnson at gmail dot com with all the details. The tow truck should arrive within 45 minutes, and your Luxury SUV will be ready at Portland Airport. Is there anything else I can help you with?"
  "$CALLER_VOICE|No, I think that covers everything. Thank you so much Karen, you've been really helpful. This was a lot less stressful than I expected."
  "$AGENT_VOICE|You're welcome Marcus. I'm glad I could help. Drive safely, and don't hesitate to call us if you need anything else. Have a good day."
)

echo "Generating ${#LINES[@]} audio clips..."
i=0
CONCAT_LIST="$TMP_DIR/concat.txt"
> "$CONCAT_LIST"

for line in "${LINES[@]}"; do
  voice="${line%%|*}"
  text="${line#*|}"
  clip="$TMP_DIR/line_$(printf '%03d' $i).aiff"
  say -v "$voice" -r "$RATE" -o "$clip" "$text"
  echo "file '$clip'" >> "$CONCAT_LIST"

  if (( i < ${#LINES[@]} - 1 )); then
    if (( i % 3 == 2 )); then
      echo "file '$PAUSE_LONG'" >> "$CONCAT_LIST"
    else
      echo "file '$PAUSE_SHORT'" >> "$CONCAT_LIST"
    fi
  fi

  i=$((i + 1))
  echo "  [$i/${#LINES[@]}] $voice: ${text:0:50}..."
done

OUTPUT="$ASSETS_DIR/fnol_call.mp3"
echo "Merging clips into $OUTPUT..."
ffmpeg -y -f concat -safe 0 -i "$CONCAT_LIST" -acodec libmp3lame -q:a 2 "$OUTPUT" 2>/dev/null

DURATION=$(ffprobe -v quiet -print_format json -show_format "$OUTPUT" | python3 -c "import sys,json; print(f'{float(json.load(sys.stdin)[\"format\"][\"duration\"]):.1f}')")
echo "Done! Generated $OUTPUT (${DURATION}s)"
