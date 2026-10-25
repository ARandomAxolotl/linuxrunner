#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
static int ignored(Display*d,XErrorEvent*e){(void)d;(void)e;return 0;}
static int has(Display*d,Window w,Atom prop,Atom value){Atom type;int format;unsigned long n,left;unsigned char*p=0;int ok=0;if(XGetWindowProperty(d,w,prop,0,1024,False,AnyPropertyType,&type,&format,&n,&left,&p)==Success&&format==32){for(unsigned long i=0;i<n;i++)if(((unsigned long*)p)[i]==value)ok=1;}if(p)XFree(p);return ok;}
static unsigned visited;
static void inspect(Display*d,Window w,unsigned depth,Atom wt,Atom dock,Atom desk,int*panel,int*desktop){
 if(depth>8||visited++>4096)return;
 XWindowAttributes a;if(XGetWindowAttributes(d,w,&a)&&a.map_state==IsViewable){if(has(d,w,wt,dock))(*panel)++;if(has(d,w,wt,desk))(*desktop)++;}
 Window r,parent,*children=0;unsigned n=0;if(XQueryTree(d,w,&r,&parent,&children,&n))for(unsigned i=0;i<n;i++)inspect(d,children[i],depth+1,wt,dock,desk,panel,desktop);if(children)XFree(children);
}
int main(int argc,char**argv){Display*d=XOpenDisplay(0);if(!d)return 2;XSetErrorHandler(ignored);Window root=DefaultRootWindow(d);int panel=0,desktop=0;Atom wt=XInternAtom(d,"_NET_WM_WINDOW_TYPE",False),dock=XInternAtom(d,"_NET_WM_WINDOW_TYPE_DOCK",False),desk=XInternAtom(d,"_NET_WM_WINDOW_TYPE_DESKTOP",False);Window owner=XGetSelectionOwner(d,XInternAtom(d,"WM_S0",False));inspect(d,root,0,wt,dock,desk,&panel,&desktop);printf("wm=%lu\npanel=%d\nsurface=%d\nready=%d\n",owner,panel,desktop,owner!=None&&panel>0&&desktop>0);XCloseDisplay(d);return argc>1&&!strcmp(argv[1],"--ready")&&!(owner!=None&&panel>0&&desktop>0)?1:0;}
