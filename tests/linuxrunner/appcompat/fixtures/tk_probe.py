#!/usr/bin/env python3
# Tk input probe: typed text plus Return is written to /tmp/ac-tk.txt.
import tkinter as tk
root = tk.Tk()
root.title('LR Tk probe')
root.geometry('360x120')
entry = tk.Entry(root, width=40)
entry.pack(padx=10, pady=20)
entry.focus_set()
def save(_event=None):
    with open('/tmp/ac-tk.txt', 'w') as f:
        f.write(entry.get() + '\n')
entry.bind('<Return>', save)
root.protocol('WM_DELETE_WINDOW', root.destroy)
root.mainloop()
