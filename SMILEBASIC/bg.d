module otya.smilebasic.bg;
import otya.smilebasic.petitcomputer;
import otya.smilebasic.error;
import derelict.sdl2.sdl;
import derelict.opengl3.gl;

struct BGChip
{
    int i;
}
//912枚まで描画されるみたい
//->899枚まで描画してその後は一番下のみ描画の様子
//縦から描画していそう
class BG
{
    BGChip[16384] chip;
    int offsetx, offsety, offsetz;
    int clipx, clipy, clipx2, clipy2;
    double scalex, scaley;
    double r;
    int homex, homey;
    int width, height;
    int rendermax = 899;
    PetitComputer petitcom;
    this(PetitComputer pc)
    {
        chip[] = BGChip(0);
        width = 25;
        height = 35;
        petitcom = pc;
        scalex = 1;
        scaley = 1;
        r = 0;
    }
    void render(float disw, float dish)
    {
        float aspect = disw / dish;
        disw /= 2;
        dish /= 2;
        float z = offsetz / 1025f;
        glColor3f(1.0, 1.0, 1.0);
        glLoadIdentity();
        glTranslatef((-offsetx + homex) / disw, -((-offsety + homey) / dish), z);
        glScalef(1.0f / aspect, 1.0f, 1.0f);
        glRotatef(360 - r, 0.0f, 0.0f, 1.0f );
        glScalef(scalex * aspect, scaley, 1f);
        version(test) glRotatef(rot_test_deg, rot_test_x, rot_test_y, rot_test_z);
        //viewport
        //clipx,clipy
        glBegin(GL_QUADS);
        int rendercount = 0;
        for(int x = 0; x < width; x++)
        {
            version(none)
            {
                for(int y = 0; y < height; y++){}
            }
            for(int y = height - 1; y >= 0; y--)//下から描画してるのか?
            {
                BGChip bgc = chip[x + y * width];
                if(!bgc.i) continue;
                int u = (bgc.i % 32) * 16;
                int v = (bgc.i / 32) * 16;
                int u2 = u + 16;
                int v2 = v + 16;
                int w = 16;
                int h = 16;
                glTexCoord2f((u) / 512f - 1 , (v2) / 512f - 1);
                glVertex3f((x * w) / disw - 1, 1 - (y * h + h) / dish, 0);
                glTexCoord2f((u) / 512f - 1, (v) / 512f - 1);
                glVertex3f((x * w) / disw - 1, 1 - (y * h) / dish, 0);
                glTexCoord2f((u2) / 512f - 1, (v) / 512f - 1);
                glVertex3f((x * w + w) / disw - 1, 1 - (y * h) / dish, 0);
                glTexCoord2f((u2) / 512f - 1, (v2) / 512f - 1);
                glVertex3f((x * w + w) / disw - 1, 1 - (y * h + h) / dish, 0);
                rendercount++;
                if(rendercount >= 899)
                {
                    break;
                }
            }
        }
        glEnd();
        glLoadIdentity();
    }
    void put(int x, int y, int screendata)
    {
        int i = screendata & 4095;
        chip[x + y * width].i = i;
    }
    void clear()
    {
        chip[0 .. width * height] = BGChip(0);
    }
    void screen(int w, int h)
    {
        this.width = w;
        this.height = h;
        this.clear();
    }
    void ofs(int x, int y, int z)
    {
        this.offsetx = x;
        this.offsety = y;
        this.offsetz = z;
    }
    void clip(int x, int y, int x2, int y2)
    {
        this.clipx = x;
        this.clipy = y;
        this.clipx2 = x2;
        this.clipy2 = y2;
    }
    void clip()
    {
        this.clipx = 0;
        this.clipy = 0;
        this.clipx2 = 400;
        this.clipy2 = 240;
    }
    void home(int x, int y)
    {
        homex = x;
        homey = y;
    }
    void scale(double x, double y)
    {
        this.scalex = x;
        this.scaley = y;
    }
    void rot(double rot)
    {
        this.r = rot;
    }
}
