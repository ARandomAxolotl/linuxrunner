// SDL2 probe: renders frames with the 2D renderer, records keyboard input and
// quits on SDL_QUIT (window close). Results in /tmp/ac-sdl.txt.
#include <SDL.h>
#include <stdio.h>
int main(int argc, char **argv) {
    (void) argc; (void) argv;
    if (SDL_Init(SDL_INIT_VIDEO) != 0) { fprintf(stderr, "SDL_Init: %s\n", SDL_GetError()); return 1; }
    SDL_Window *w = SDL_CreateWindow("LR SDL2 probe", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 320, 200, 0);
    SDL_Renderer *r = w ? SDL_CreateRenderer(w, -1, 0) : NULL;
    if (!r) { fprintf(stderr, "SDL renderer: %s\n", SDL_GetError()); return 1; }
    SDL_RendererInfo info; SDL_GetRendererInfo(r, &info);
    unsigned frames = 0; int key = 0, running = 1;
    FILE *out = fopen("/tmp/ac-sdl.txt", "w");
    while (running) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) running = 0;
            if (e.type == SDL_KEYDOWN && !key) { key = 1; fprintf(out, "KEY_OK %s\n", SDL_GetKeyName(e.key.keysym.sym)); fflush(out); }
        }
        SDL_SetRenderDrawColor(r, (Uint8) (frames * 3), 80, 160, 255);
        SDL_RenderClear(r);
        SDL_Rect box = {(int) (frames % 280), 80, 40, 40};
        SDL_SetRenderDrawColor(r, 255, 255, 255, 255);
        SDL_RenderFillRect(r, &box);
        SDL_RenderPresent(r);
        if (++frames == 60) { fprintf(out, "FRAMES_OK renderer=%s\n", info.name); fflush(out); }
        SDL_Delay(16);
    }
    fprintf(out, "QUIT_OK frames=%u\n", frames); fclose(out);
    SDL_DestroyRenderer(r); SDL_DestroyWindow(w); SDL_Quit();
    return 0;
}
