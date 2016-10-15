Vitality
========

(Vit)ality is a plugin that makes (V)im play nicely with (i)Term 2 and
(t)mux.

Features
--------

Vitality restores the `FocusLost` and `FocusGained` autocommand functionality.
Now Vim can save when iTerm 2 loses focus, even if it's inside tmux!

It also handles switching the cursor to a bar shaped one when in insert mode,
and restoring it when not.

Pull requests for other helpful behavior are welcome.

Installation and Usage
----------------------

Use Pathogen to install.

You shouldn't need to do anything else, but you can read `:help vitality` if
you're curious.

Note on later versions of tmux (1.9.x or higher)
------------------------------------------------

If you find that `FocusLost` events are not working in later versions of tmux
try adding the following line to your .tmux.conf.

    set -g focus-events on

Don't forget to restart all your tmux sessions for this setting to take effect
(or just run the command in tmux itself to avoid having to restart).

License
-------

MIT/X11
