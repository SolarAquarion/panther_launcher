#include <gtk/gtk.h>
#include <gtk/gtkbutton.h>
#include <panel-applet.h>
#include <unistd.h>
#include <stdlib.h>
#include "dbus.h"

extern char **environ;

static gboolean applet_fill_cb (PanelApplet * applet, const gchar * iid, gpointer data);

PANEL_APPLET_IN_PROCESS_FACTORY ("PantherAppletFactory", PANEL_TYPE_APPLET, applet_fill_cb, NULL);

static void launch(char silent) {

	int pid=fork();
	char *args[3];

    if (silent == 0) {
        args[1] = NULL;
    } else {
        args[1] = "-s";
        args[2] = NULL;
    }
	if (pid == 0) {
		// prelaunch panther launcher
		args[0]="/usr/bin/panther_launcher";
		execve(args[0],args,environ);
		args[0]="/usr/local/bin/panther_launcher";
		execve(args[0],args,environ);
		exit(0);
	}
}

static void button_clicked(GtkWidget *widget, GdkEvent  *event, gpointer   user_data) {

    GError *error = NULL;

    ComRastersoftPantherRemotecontrol *proxy;
    proxy = com_rastersoft_panther_remotecontrol_proxy_new_for_bus_sync (G_BUS_TYPE_SESSION,
                                                  G_DBUS_PROXY_FLAGS_NONE,
                                                  "com.rastersoft.panther.remotecontrol",
                                                  "/com/rastersoft/panther/remotecontrol",
                                                  NULL, /* GCancellable */
                                                  &error);
    if (proxy != NULL) {
        error = NULL;
        if (com_rastersoft_panther_remotecontrol_call_do_show_sync(proxy,NULL,&error)) {
            printf("do show True\n");
        } else {
            printf("do show false: %d; %s\n",error->code,error->message);
        }
        g_object_unref(proxy);
    } else {
        printf("Error getting proxy\n");
    }
}

static gboolean applet_fill_cb (PanelApplet *applet, const gchar * iid, gpointer data) {

	gboolean retval = FALSE;
	static gboolean set_name = FALSE;

	if (g_strcmp0 (iid, "PantherApplet") == 0) {
		if (!set_name) {
			g_set_application_name ("PantherLauncher");
			set_name=TRUE;
            launch(1);
		}
		gtk_container_set_border_width(GTK_CONTAINER (applet), 0);
		gtk_widget_show_all(GTK_WIDGET(applet));
		GtkWidget* main_button = gtk_label_new(NULL);
		gtk_widget_set_margin_start(main_button,3);
		gtk_widget_set_margin_end(main_button,3);
		gtk_label_set_markup(GTK_LABEL(main_button),"<b>Applications</b>");
		GtkWidget* eventbox = gtk_event_box_new();
		gtk_container_add(GTK_CONTAINER(applet),eventbox);
		gtk_container_add(GTK_CONTAINER(eventbox),main_button);
		gtk_widget_show_all(GTK_WIDGET(applet));
		g_object_connect(G_OBJECT(eventbox),"signal::button_release_event",button_clicked,NULL,NULL);
		retval = TRUE;
	}

	return retval;
}
