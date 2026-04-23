#!/bin/bash
set -e

TMPDIR=$(mktemp -d)
OUTDIR="$(dirname "$0")/../assets"
AGENT_VOICE="Samantha"
CALLER_VOICE="Shelley (English (US))"
RATE=180

i=0
speak() {
  local voice="$1"
  local text="$2"
  local file=$(printf "%s/%03d.aiff" "$TMPDIR" $i)
  say -v "$voice" -r $RATE -o "$file" "$text"
  i=$((i + 1))
}

pause() {
  local dur="${1:-0.6}"
  local file=$(printf "%s/%03d.aiff" "$TMPDIR" $i)
  ffmpeg -y -f lavfi -i anullsrc=r=44100:cl=mono -t "$dur" -q:a 9 "$file" 2>/dev/null
  i=$((i + 1))
}

# --- CALL SCRIPT: Emily Rodriguez calling about Running Shoes sole separation ---

speak "$AGENT_VOICE" "Thank you for calling the call center. My name is Alex. How can I help you today?"
pause 0.5

speak "$CALLER_VOICE" "Hi Alex. My name is Emily Rodriguez. I purchased a pair of running shoes from you guys a few weeks ago and I'm having a problem with them."
pause 0.4

speak "$AGENT_VOICE" "I'm sorry to hear that, Emily. Let me pull up your account. Can you give me the phone number associated with your order?"
pause 0.3

speak "$CALLER_VOICE" "Sure, it's 5 5 5, 3 4 5, 6 7 8 9."
pause 0.4

speak "$AGENT_VOICE" "Great, I found your account. And your email address is emily dot rodriguez at gmail dot com, is that correct?"
pause 0.3

speak "$CALLER_VOICE" "Yes, that's right."
pause 0.4

speak "$AGENT_VOICE" "Perfect. I can see your order for the running shoes. Can you tell me what's going on with them?"
pause 0.3

speak "$CALLER_VOICE" "So I've been using them for my morning runs, about three or four times a week. And last week I noticed the sole on the left shoe is starting to separate from the upper part. There's a visible gap forming near the toe area."
pause 0.4

speak "$AGENT_VOICE" "Oh no, that definitely shouldn't be happening, especially after just a few weeks of use. Is it just the left shoe, or both?"
pause 0.3

speak "$CALLER_VOICE" "It's mainly the left shoe. The right one seems fine so far. But I'm worried it might happen to that one too. I really liked these shoes otherwise. They're super comfortable for running."
pause 0.4

speak "$AGENT_VOICE" "I completely understand your concern. That sounds like it could be a manufacturing defect. Let me check if we've had similar reports. Can you hold on just a moment?"
pause 0.8

speak "$AGENT_VOICE" "Emily, I'm looking at your account and I can see the order. This does appear to be a quality issue. We'd like to make this right for you. I can offer you a full replacement pair, or if you prefer, a full refund."
pause 0.3

speak "$CALLER_VOICE" "I think I'd like a replacement if possible. Like I said, I really do like the shoes when they work properly. Is there any way to get an expedited shipment? I have a half marathon coming up in three weeks."
pause 0.4

speak "$AGENT_VOICE" "Absolutely. Since you're a valued customer, I can send out a replacement pair with two day express shipping at no extra charge. You should have them well before your half marathon."
pause 0.3

speak "$CALLER_VOICE" "That would be amazing, thank you so much. Should I send the defective pair back?"
pause 0.4

speak "$AGENT_VOICE" "Yes, we'll email you a prepaid return label. Just ship them back within thirty days. And Emily, I want to make sure, would you like the same size and color?"
pause 0.3

speak "$CALLER_VOICE" "Yes, same size and color please. Everything else about them was great."
pause 0.4

speak "$AGENT_VOICE" "Perfect. I've placed the replacement order. You should receive a confirmation email shortly, along with the return label. Is there anything else I can help you with today?"
pause 0.3

speak "$CALLER_VOICE" "No, that's everything. You've been really helpful. Thank you, Alex."
pause 0.3

speak "$AGENT_VOICE" "Thank you, Emily. Good luck with your half marathon! Have a great day."

# --- Combine all clips ---
echo "Combining $i audio clips..."
FILELIST="$TMPDIR/filelist.txt"
for f in $(ls "$TMPDIR"/*.aiff | sort); do
  echo "file '$f'" >> "$FILELIST"
done

ffmpeg -y -f concat -safe 0 -i "$FILELIST" -codec:a libmp3lame -b:a 128k "$OUTDIR/demo_call_2.mp3" 2>/dev/null

echo "Generated: $OUTDIR/demo_call_2.mp3"
rm -rf "$TMPDIR"
echo "Done!"
