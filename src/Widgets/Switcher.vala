// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//
//  Copyright (C) 2011-2012 Giulio Collura
//  Copyright (C) 2014 Corentin Noël <tintou@mailoo.org>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

using Gtk;

public class Panther.Widgets.Switcher : Gtk.Box {

    public int size {
        get {
            return (int) buttons.size;
        }
    }

    private Gtk.Stack stack;
    private Gee.HashMap<Gtk.Widget, Gtk.ToggleButton> buttons;
    public signal void on_stack_changed ();
    
    public Switcher () {
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 2;
        can_focus = false;
        buttons = new Gee.HashMap<Gtk.Widget, Gtk.ToggleButton> (null, null);
        pack_start (new Gtk.Grid (), true, true, 0);
        pack_end (new Gtk.Grid (), true, true, 0);
    }

    public void set_stack (Gtk.Stack stack) {
        if (this.stack != null) {
            clear_children ();
        }
        this.stack = stack;
        populate_switcher ();
        connect_stack_signals ();
        update_selected ();
    }

    private void add_child (Gtk.Widget widget) {
        var button = new Gtk.ToggleButton.with_label ((buttons.size +1).to_string ());
        button.width_request = 30;
        button.can_focus = false;
        button.get_style_context ().add_class ("switcher");
        button.button_release_event.connect (() => {
            foreach (var entry in buttons.entries) {
                if (entry.value == button)
                    on_button_clicked (entry.key);
                entry.value.active = false;
            }
            button.active = true;
            return true;
        });

        add (button);
        buttons.set (widget, button);
        if (buttons.size == 1)
            button.active = true;

        // show all children after update
        show_all ();
    }
    
    public override void show () {
        base.show ();
        if (buttons.size <= 1)
            hide ();
    }

    
    public override void show_all () {
        base.show_all ();
        if (buttons.size <= 1)
            hide ();
    }

    private void on_button_clicked (Gtk.Widget widget) {
        stack.set_visible_child (widget);
        on_stack_changed ();
    }

    private void populate_switcher () {
        foreach (var child in stack.get_children ()) {
            add_child (child);
        }
    }

    private void on_stack_child_removed (Gtk.Widget widget) {
        var button = buttons.get (widget);
        remove (button);
        buttons.unset (widget);
    }

    private void connect_stack_signals () {
        stack.add.connect_after (add_child);
        stack.remove.connect_after (on_stack_child_removed);
    }

    public void clear_children () {
        foreach (weak Gtk.Widget button in get_children ()) {
            button.hide ();
            if (button.get_parent () != null)
                remove (button);
        }
    }
    
    public void update_selected () {
        foreach (var entry in buttons.entries) {
            if (entry.key == stack.get_visible_child ()) {
                entry.value.active = true;
            } else {
                entry.value.active = false;
            }
        }
    }
}
