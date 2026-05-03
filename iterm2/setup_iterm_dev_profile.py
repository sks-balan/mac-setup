import plistlib
import os

PLIST_PATH = os.path.expanduser('~/Library/Preferences/com.googlecode.iterm2.plist')

# Action codes
ESC_SEQ  = 10   # Send Escape Sequence (ESC is prepended automatically)
HEX_CODE = 11   # Send Hex Code

def key(action, text):
    return {'Version': 2, 'Apply Mode': 0, 'Action': action, 'Text': text, 'Escaping': 2}

# Key format: "0x<unicode>-0x<modifiers>-0x<scancode>"
# Modifiers: 0x200000 = numpad/special keys base
#            + 0x80000  = Option
#            + 0x100000 = Command
#            + 0x40000  = Control
#            + 0x20000  = Shift
KEY_MAPPINGS = {
    # --- Word movement ---
    '0xf702-0x280000-0x7b': key(ESC_SEQ,  'b'),          # Option+Left  → backward-word
    '0xf703-0x280000-0x7c': key(ESC_SEQ,  'f'),          # Option+Right → forward-word
    '0xf702-0x240000-0x7b': key(ESC_SEQ,  'b'),          # Ctrl+Left    → backward-word
    '0xf703-0x240000-0x7c': key(ESC_SEQ,  'f'),          # Ctrl+Right   → forward-word

    # --- Line movement ---
    '0xf702-0x300000-0x7b': key(HEX_CODE, '0x01'),       # Cmd+Left     → beginning of line
    '0xf703-0x300000-0x7c': key(HEX_CODE, '0x05'),       # Cmd+Right    → end of line
    '0xf729-0x200000-0x73': key(HEX_CODE, '0x01'),       # Home         → beginning of line
    '0xf72b-0x200000-0x77': key(HEX_CODE, '0x05'),       # End          → end of line

    # --- Delete operations ---
    '0x7f-0x80000-0x33':    key(HEX_CODE, '0x1b 0x7f'),  # Option+Backspace → delete word backward
    '0xf728-0x280000-0x75': key(HEX_CODE, '0x1b 0x64'),  # Option+Delete    → delete word forward
    '0x7f-0x100000-0x33':   key(HEX_CODE, '0x15'),       # Cmd+Backspace    → delete to start of line
    '0xf728-0x300000-0x75': key(HEX_CODE, '0x0b'),       # Cmd+Delete       → delete to end of line

    # --- Scroll / Page ---
    '0xf72c-0x200000-0x74': key(ESC_SEQ,  '[5~'),        # Page Up   → send PgUp to app
    '0xf72d-0x200000-0x79': key(ESC_SEQ,  '[6~'),        # Page Down → send PgDn to app
    '0xf700-0x300000-0x7e': key(HEX_CODE, '0x01 0x0b'),  # Cmd+Up    → beginning of line + clear down
    '0xf701-0x300000-0x7d': key(HEX_CODE, '0x05'),       # Cmd+Down  → end of line
}

with open(PLIST_PATH, 'rb') as f:
    prefs = plistlib.load(f)

profiles = prefs.get('New Bookmarks', [])
dev_guid = None
for p in profiles:
    if p.get('Name') == 'Dev':
        p['Keyboard Map'] = KEY_MAPPINGS
        p['Option Key Sends'] = 2       # Esc+ for Option key
        p['Right Option Key Sends'] = 2
        dev_guid = p.get('Guid')
        print(f"Updated Dev profile with {len(KEY_MAPPINGS)} key mappings")
        break

# Set Dev as the default profile
if dev_guid:
    prefs['Default Bookmark Guid'] = dev_guid
    print("Set Dev as default profile")
else:
    print("WARNING: Dev profile not found — create it in iTerm2 first, then re-run this script")

with open(PLIST_PATH, 'wb') as f:
    plistlib.dump(prefs, f)

print("Done — restart iTerm2 to apply")
