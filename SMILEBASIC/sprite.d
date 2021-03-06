module otya.smilebasic.sprite;
import otya.smilebasic.petitcomputer;
import otya.smilebasic.error;
import derelict.sdl2.sdl;
import derelict.opengl3.gl;
enum SpriteAttr
{
    none = 0,
    show =      0b00001,
    rotate90 =  0b00010,
    rotate180 = 0b00100,
    rotate270 = 0b00110,
    hflip =     0b01000,//yoko
    vflip =     0b10000,//tate
}
enum SpriteAnimTarget
{
    XY = 0,
    Z,
    UV,
    I,
    R,
    S,
    C,
    V,
    relative = 8,
}
struct SpriteAnimState
{
    union
    {
        struct
        {
            double x, y;
        }
        struct
        {
            double z;
        }
        struct
        {
            int u, v;
        }
        struct
        {
            int i;
        }
        struct
        {
            double r;
        }
        struct
        {
            double scalex, scaley;
        }
        struct
        {
            uint c;
        }
        struct
        {
            double var;
        }
    }
}

struct SpriteAnimData
{
    bool relative;//相対座標として扱うか
    int frame;//何フレームごとに動かすか
    int elapse;//何フレーム目か
    //int repeatcount;//何回目のループか
    //int loop;//何回ループするか(0で無限ループ)
    bool interpolation;//線形補完するかどうか
    SpriteAnimState data;
    SpriteAnimState old;
    int load(int i, ref SpriteData sprite, SpriteAnimTarget target, double[] data, SpriteAnimData* old)
    {
        this.frame = cast(int)data[i];
        if(this.frame < 0)
        {
            this.frame = -this.frame;
            interpolation = true;
        }
        if(this.frame == 0)
        {
            throw new IllegalFunctionCall("SPANIM");
        }
        i++;
        switch(target)
        {
            case SpriteAnimTarget.XY:
                this.data.x = cast(int)data[i++];
                this.data.y = cast(int)data[i++];
                this.old.x = old ? old.data.x : sprite.x;
                this.old.y = old ? old.data.y : sprite.y;
                break;
            case SpriteAnimTarget.Z:
                this.data.z = cast(int)data[i++];
                this.old.z = old ? old.data.z : sprite.z;
                break;
            case SpriteAnimTarget.UV:
                this.data.u = cast(int)data[i++];
                this.data.v = cast(int)data[i++];
                this.old.u = old ? old.data.u : sprite.u;
                this.old.v = old ? old.data.v : sprite.v;
                break;
            case SpriteAnimTarget.I:
                this.data.i = cast(int)data[i++];
                this.old.i = old ? old.data.i : sprite.defno;
                break;
            case SpriteAnimTarget.R:
                this.data.r = data[i++];
                this.old.r = old ? old.data.r : sprite.r;
                break;
            case SpriteAnimTarget.S:
                this.data.scalex = data[i++];
                this.data.scaley = data[i++];
                this.old.scalex = old ? old.data.scalex : sprite.scalex;
                this.old.scaley = old ? old.data.scaley : sprite.scaley;
                break;
            case SpriteAnimTarget.C:
                this.data.c = cast(uint)data[i++];
                break;
            case SpriteAnimTarget.V:
                this.data.var = data[i++];
                break;
            default:
                throw new IllegalFunctionCall("SPANIM");
        }
        return i;
    }
}
struct SpriteDef
{
    int u, v, w, h, hx, hy;
    SpriteAttr a;
}
struct SpriteData
{
    bool isAnim;
    int id;
    int defno;
    double x, y;
    int homex, homey;
    int z;/*!*/
    int u, v, w, h;//個々で保持してるみたい,SPSETをして後でSPDEFをしても変化しない
    uint color;
    double[8] var;
    SpriteAttr attr;
    bool define;//定義されてればtrue
    double scalex;
    double scaley;
    double r;
    this(int id)
    {
        this.id = id;
        z = 0;
        define = false;
    }
    this(int id, int defno)
    {
        x = 0;
        y = 0;
        z = 0;
        r = 0;
        this.id = id;
        this.defno = defno;
        this.color = -1;
        this.attr = SpriteAttr.show;
        this.define = true;
        scalex = 1;
        scaley = 1;
    }
    this(int id, int u, int v, int w, int h)
    {
        x = 0;
        y = 0;
        z = 0;
        r = 0;
        this.id = id;
        this.u = u;
        this.v = v;
        this.w = w;
        this.h = h;
        this.color = -1;
        this.attr = SpriteAttr.show;
        this.define = true;
        scalex = 1;
        scaley = 1;
    }
    this(int id, ref SpriteDef spdef, int defno)
    {
        x = 0;
        y = 0;
        z = 0;
        r = 0;
        this.id = id;
        this.u = spdef.u;
        this.v = spdef.v;
        this.w = spdef.w;
        this.h = spdef.h;
        this.color = -1;
        this.attr = spdef.a;
        this.homex = spdef.hx;
        this.homey = spdef.hy;
        this.define = true;
        scalex = 1;
        scaley = 1;
        this.defno = defno;
    }
    SpriteAnimData[][SpriteAnimTarget.V] anim;
    int[SpriteAnimTarget.V] animindex;
    int[SpriteAnimTarget.V] animloop;
    int[SpriteAnimTarget.V] animloopcnt;
    void setAnimation(SpriteAnimData[] anim, SpriteAnimTarget sat, int loop)
    {
        this.anim[sat] = anim;
        if(loop < 0)
        {
            throw new IllegalFunctionCall("SPANIM");
        }
        animloop[sat] = loop;
        animloopcnt[sat] = 0;
        isAnim = true;
    }
    void clear()
    {
        this.define = false;
        this.attr = SpriteAttr.none;
    }
    void change(SpriteDef s)
    {
        this.u = s.u;
        this.v = s.v;
        this.w = s.w;
        this.h = s.h;
        this.homex = s.hx;
        this.homey = s.hy;
        this.attr = s.a;
    }
    //SPLINK用
    SpriteData* parent;
    //SPLINKの親は子より小さい管理番号でしかなれないのでsprite->child->nextのX座標を加算すればなんとかなる
    //->挙動的に違う
    int linkx, linky;
}
class Sprite
{
    SpriteDef[] defSPDEFTable;
    SpriteDef[] SPDEFTable;
    SpriteData[] sprites;
    PetitComputer petitcom;
    string spdefTableFile = "spdef.csv";
    int spmax = 512;
    void initUVTable()
    {
        SPDEFTable = new SpriteDef[4096];
        defSPDEFTable = new SpriteDef[4096];
        import std.csv;
        import std.typecons;//I	X	Y	W	H	HX	HY	ATTR
        import std.file;
        import std.stdio;
        import std.algorithm;
        auto file = File(spdefTableFile, "r");
        file.readln();//一行読み飛ばす
        auto csv = file.byLine.joiner("\n").csvReader!(Tuple!(int, "I", int, "X" ,int, "Y", int, "W", int, "H", int, "HX", int, "HY", int, "ATTR"));
        foreach(record; csv)
        {
            defSPDEFTable[record.I] = SpriteDef(record.X, record.Y, record.W, record.H, record.HX, record.HY, cast(SpriteAttr)record.ATTR);
        }
        spdef;
    }
    void spdef()
    {
        this.SPDEFTable[] = (this.defSPDEFTable)[];
    }
    void spchr(int i, int d)
    {
        i = spid(i);
        sprites[i].change(SPDEFTable[d]);
    }
    void spchr(int id, int u, int v, int w, int h, SpriteAttr attr)
    {
        id = spid(id);
        auto spdef = SpriteDef(u, v, w, h, sprites[id].homex, sprites[id].homey, attr);
        sprites[id].change(spdef);
    }
    this(PetitComputer petitcom)
    {
        sprites = new SpriteData[512];
        zsortedSprites = new SpriteData*[512];
        for(int i = 0; i < sprites.length; i++)
        {
            zsortedSprites[i] = &sprites[i];
            sprites[i] = SpriteData(i);
        }
        initUVTable;
        this.petitcom = petitcom;
        list = new SpriteBucket[512];
        for(int i = 0; i < 512; i++)
        {
            list[i] = new SpriteBucket();
        }
        buckets = new SpriteBucket[1024 + 256];
        listptr = list.ptr;
        bucketsptr = buckets.ptr;
    }
    void animation(SpriteData* sprite)
    {
        foreach(i, ref d; sprite.anim)
        {
            if(!d) continue;//未定義
            SpriteAnimTarget target = cast(SpriteAnimTarget)i;
            int index = sprite.animindex[i];
            SpriteAnimData* data = &d[index];
            data.elapse = data.elapse + 1;
            auto frame = data.elapse;
            if(frame == 1)
            {
                if(!data.interpolation)
                {
                    switch(target)
                    {
                        case SpriteAnimTarget.XY:
                            sprite.x = data.data.x;
                            sprite.y = data.data.y;
                            break;
                        case SpriteAnimTarget.Z:
                            sprite.z = cast(int)data.data.z;
                            break;
                        case SpriteAnimTarget.UV:
                            sprite.u = data.data.u;
                            sprite.v = data.data.v;
                            break;
                        case SpriteAnimTarget.I:
                            sprite.defno = data.data.i;
                            spchr(sprite.id, sprite.defno);
                            break;
                        case SpriteAnimTarget.R:
                            sprite.r = data.data.r;
                            break;
                        case SpriteAnimTarget.S:
                            sprite.scalex = data.data.scalex;
                            sprite.scaley = data.data.scaley;
                            break;
                        case SpriteAnimTarget.C:
                            break;
                        case SpriteAnimTarget.V:
                            break;
                        default:
                            break;
                    }
                }
            }
            if(data.interpolation)
            {
                //線形補完する奴
                switch(target)
                {
                    case SpriteAnimTarget.XY:
                        sprite.x = data.old.x + ((data.data.x - data.old.x) / data.frame) * frame;
                        sprite.y = data.old.y + ((data.data.y - data.old.y) / data.frame) * frame;
                        break;
                    case SpriteAnimTarget.Z:
                        sprite.z = cast(int)(data.old.z + ((data.data.z - data.old.z) / data.frame) * frame);
                        break;
                    case SpriteAnimTarget.UV:
                        sprite.u = data.old.u + ((data.data.u - data.old.u) / data.frame) * frame;
                        sprite.v = data.old.v + ((data.data.v - data.old.v) / data.frame) * frame;
                        break;
                    case SpriteAnimTarget.I:
                        sprite.defno = data.old.i + ((data.data.i - data.old.i) / data.frame) * frame;
                        spchr(sprite.id, sprite.defno);
                        break;
                    case SpriteAnimTarget.R:
                        sprite.r = data.old.r + ((data.data.r - data.old.r) / data.frame) * frame;
                        break;
                    case SpriteAnimTarget.S:
                        sprite.scalex = data.old.scalex + ((data.data.scalex - data.old.scalex) / data.frame) * frame;
                        sprite.scaley = data.old.scaley + ((data.data.scaley - data.old.scaley) / data.frame) * frame;
                        break;
                    case SpriteAnimTarget.C:
                        break;
                    case SpriteAnimTarget.V:
                        break;
                    default:
                        break;
                }
            }
            if(frame >= data.frame)
            {
                sprite.animindex[i] = (sprite.animindex[i] + 1) % cast(int)d.length;
                data.elapse = 0;
                if(sprite.animloop[i] == 0)
                {
                    continue;
                }
                sprite.animloop[i]++;
                if(sprite.animloop[i] >= sprite.animloopcnt[i])
                {
                    sprite.anim[i] = null;
                    continue;
                }
                continue;
            }
        }
    }
    bool lll;
    import std.algorithm;
    SpriteData*[] zsortedSprites;
    bool zChange;
    class SpriteBucket
    {
        SpriteData* sprite;
        SpriteBucket next;
        SpriteBucket last;
    }
    SpriteBucket[] list;
    SpriteBucket[] buckets;
    SpriteBucket* listptr;
    SpriteBucket* bucketsptr;
    void render()
    {
        //とりあえずZ更新されたら描画時にまとめてソート
        //thread safe.....
        if(zChange)
        {
            
            import std.range;
            import std.algorithm;
            zChange = false;
            /*//TimSortImpl!(binaryFun!("a.z < b.z"), Range).sort(zsortedSprites, null);
            try
            {
                sort!("a.z > b.z", SwapStrategy.stable)(zsortedSprites);
            }
            catch(Throwable t)
            {
            }//*/
            //バケットソートっぽい奴
            //基本的にほぼソートされてるので挿入ソートのほうが早そう
            //std.algorithmソートだと例外出る
            //m = 256+1024
            //n = 512
            import std.stdio;
            //writeln("=============START==========");
            //writeln("sort");
            foreach(i, ref s; sprites)
            {
                //if(!s.define) continue;
                auto zet = s.z + 256;
                listptr[i].sprite = &s;
                if(bucketsptr[zet])
                {
                    //listptr[i].next = bucketsptr[zet].last;
                    bucketsptr[zet].last.next = listptr[i];
                    bucketsptr[zet].last = listptr[i];
                    listptr[i].next = null;
                }
                else
                {
                    bucketsptr[zet] = listptr[i].last = listptr[i];
                    listptr[i].next = null;
                }
            }
            int j;
            foreach_reverse(i, b; buckets)
            {
                if(b)
                {
                    while(b)
                    {
                        //writefln("z:%d, id:%d", b.sprite.z, b.sprite.id);
                        zsortedSprites[j] = b.sprite;
                        j++;
                        b = b.next;
                    }
                    bucketsptr[i] = null;
                }
            }
        }
        float disw = 200f, dish = 120f, disw2 = 400f, dish2 = 240f;
        if(petitcom.xscreenmode == 2)
        {
            disw = 160f;
            disw2 = 320f;
            dish = 240f;
            dish2 = 480f;
        }
        auto texture = petitcom.GRP[petitcom.sppage].glTexture;
        float aspect = disw2 / dish2;
        float z = -0.01f;
        int spmax = petitcom.xscreenmode == 1 ? this.spmax : -1;//XSCREENが2,3じゃないと下画面は描画しない
        glBindTexture(GL_TEXTURE_2D, texture);
        glEnable(GL_TEXTURE_2D);
        // glDisable(GL_TEXTURE_2D);
        version(test) glLoadIdentity();
        glLoadIdentity();
        foreach(i, sprite; zsortedSprites)
        {
            if(i == spmax)
            {
                disw = 160f;
                disw2 = 320f;
                glViewport(40, 0, 320, 240);
                aspect = disw2 / dish2;
            }
            //定義されてたら動かす
            if(sprite.define)
            {
                animation(sprite);
            }
            if(sprite.attr & SpriteAttr.show)
            {
                int x, y;
                if(sprite.parent)
                {
                    x += cast(int)(sprite.x + sprite.parent.linkx);
                    y += cast(int)(sprite.y + sprite.parent.linky);
                }
                else
                {
                    x = cast(int)sprite.x;// - cast(int)(sprite.homex * sprite.scalex);
                    y = cast(int)sprite.y;// - cast(int)(sprite.homey * sprite.scaley);
                }
                sprite.linkx = x;
                sprite.linky = y;
                auto homex2 = ((sprite.w / 2 ) - sprite.homex) / disw;
                auto homey2 = ((sprite.h / 2 ) - sprite.homey) / dish;
                int w = sprite.w;
                int h = sprite.h;
                
                if((sprite.attr & SpriteAttr.rotate90) == SpriteAttr.rotate90)
                {
                    swap(w, h);
                }
                int x2 = cast(int)x + w;//-1
                int y2 = cast(int)y + h;
                int u = cast(int)sprite.u;
                int v = cast(int)sprite.v;
                int u2 = cast(int)sprite.u + sprite.w;//-1
                int v2 = cast(int)sprite.v + sprite.h;
                z = (sprite.z - 1) / 1025f;//スプライトの描画順が一番上だけどスプライトは最後に描画しないといけないのでZ - 1で一番上にする
                float flipx = cast(float)sprite.scalex, flipy = cast(float)sprite.scaley, flipx2 = x, flipy2 = y;
                if(sprite.attr & SpriteAttr.hflip)
                {
                    flipx = -flipx;
                    flipx2 = x2 - cast(int)(sprite.homex * sprite.scalex);//sprite.homex * sprite.scalex);
                }
                if(sprite.attr & SpriteAttr.vflip)
                {
                    flipy = -flipy;
                    flipy2 = y2 - cast(int)(sprite.homey * sprite.scaley);
                }
                version(test) glRotatef(rot_test_deg, rot_test_x, rot_test_y, rot_test_z);

                glTranslatef((flipx2) / disw - 1,
                             1 - ((flipy2) / dish), 0);
                //glTranslatef((flipx2) / dish - 1,1 - ((flipy2) / dish), 0);
                //glScalef(flipx, flipy, 1f); 
                //アスペクト比を調節しないといけないらしい
                //https://groups.google.com/forum/#!topic/android-group-japan/45mjecPSY4s
                //http://www.tnksoft.com/blog/?p=2889
                glScalef(1.0f / aspect, 1.0f, 1.0f);
                glRotatef(360 - sprite.r, 0.0f, 0.0f, 1.0f );
                glScalef(flipx * aspect, flipy, 1f);
                glBegin(GL_QUADS);
                glColor4ubv(cast(ubyte*)&sprite.color);
                if((sprite.attr& 0b111) == SpriteAttr.show)
                {
                    glTexCoord2f(u / 512f - 1, v / 512f - 1);
                    glVertex3f(-((sprite.w) / disw2 - homex2) , ((sprite.h) / dish2 - homey2), z);//1
                    glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);
                    glVertex3f(-((sprite.w) / disw2 - homex2), -((sprite.h) / dish2 + homey2), z);//2
                    glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);
                    glVertex3f((sprite.w) / disw2 + homex2, -((sprite.h) / dish2 + homey2), z);//3//y+--+x--++
                    glTexCoord2f(u2 / 512f - 1, v / 512f - 1);
                    glVertex3f((sprite.w) / disw2 + homex2, ((sprite.h) / dish2 - homey2), z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                if((sprite.attr & SpriteAttr.rotate270) == SpriteAttr.rotate270)
                {
                    glTexCoord2f(u2 / 512f - 1, v / 512f - 1);//3
                    glVertex3f(-((sprite.w) / disw2 - homex2), ((sprite.h) / dish2 - homey2), z);//1
                    glTexCoord2f(u / 512f - 1, v / 512f - 1);//1
                    glVertex3f(-((sprite.w) / disw2 - homex2), -((sprite.h) / dish2 + homey2), z);//2
                    glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);//2
                    glVertex3f((sprite.w) / disw2 + homex2, -((sprite.h) / dish2 + homey2), z);//3
                    glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);//4
                    glVertex3f((sprite.w) / disw2 + homex2, ((sprite.h) / dish2 - homey2), z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                if((sprite.attr & SpriteAttr.rotate90) == SpriteAttr.rotate90)
                {
                    glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);//2
                    glVertex3f(-((sprite.w) / disw2 - homex2), ((sprite.h) / dish2 - homey2), z);//1
                    glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);//3
                    glVertex3f(-((sprite.w) / disw2 - homex2), -((sprite.h) / dish2 + homey2), z);//2
                    glTexCoord2f(u2 / 512f - 1, v / 512f - 1);//4
                    glVertex3f((sprite.w) / disw2 + homex2, -((sprite.h) / dish2 + homey2), z);//3
                    glTexCoord2f(u / 512f - 1, v / 512f - 1);//1
                    glVertex3f((sprite.w) / disw2 + homex2, ((sprite.h) / dish2 - homey2), z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                if((sprite.attr & SpriteAttr.rotate180) == SpriteAttr.rotate180)
                {
                    glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);//4
                    glVertex3f(-((sprite.w) / disw2 - homex2), ((sprite.h) / dish2 - homey2), z);//1
                    glTexCoord2f(u2 / 512f - 1, v / 512f - 1);//3
                    glVertex3f(-((sprite.w) / disw2 - homex2), -((sprite.h) / dish2 + homey2), z);//2
                    glTexCoord2f(u / 512f - 1, v / 512f - 1);//1
                    glVertex3f((sprite.w) / disw2 + homex2, -((sprite.h) / dish2 + homey2), z);//3
                    glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);//2
                    glVertex3f((sprite.w) / disw2 + homex2, ((sprite.h) / dish2 - homey2), z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                glTexCoord2f(u / 512f - 1, v / 512f - 1);
                glVertex3f(-((sprite.w) / disw2 - homex2), ((sprite.h) / dish2 - homey2), z);//1
                glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);
                glVertex3f(-((sprite.w) / disw2 - homex2), -((sprite.h) / dish2 + homey2), z);//2
                glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);
                glVertex3f((sprite.w) / disw2 + homex2, -((sprite.h) / dish2 + homey2), z);//3
                glTexCoord2f(u2 / 512f - 1, v / 512f - 1);
                glVertex3f((sprite.w) / disw2 + homex2, ((sprite.h) / dish2 - homey2), z);//4
                glEnd();
                glLoadIdentity();
                continue;
            }
        }
    }
    int spid(int id)
    {
        if(petitcom.displaynum == 1)
        {
            return id + this.spmax;
        }
        return id;
    }
    void spset(int id, int defno)
    {
        id = spid(id);
        sprites[id] = SpriteData(id, SPDEFTable[defno], defno);
    }
    void spset(int id, int u, int v, int w, int h, SpriteAttr attr)
    {
        id = spid(id);
        auto spdef = SpriteDef(u, v, w, h, 0, 0, attr);
        sprites[id] = SpriteData(id, spdef, 0/*要調査*/);
    }
    void spofs(int id, double x, double y)
    {
        id = spid(id);
        sprites[id].x = x;
        sprites[id].y = y;
    }
    void spofs(int id, double x, double y, int z)
    {
        id = spid(id);
        sprites[id].x = x;
        sprites[id].y = y;
        sprites[id].z = z;
        zChange = true;
    }
    void getspofs(int id, out  double x, out double y, out int z)
    {
        id = spid(id);
        x = sprites[id].x;
        y = sprites[id].y;
        z = sprites[id].z;
    }
    void sphide(int id)
    {
        id = spid(id);
        sprites[id].attr ^= SpriteAttr.show;
    }
    void spshow(int id)
    {
        id = spid(id);
        sprites[id].attr |= SpriteAttr.show;
    }
    void spanim(int id, wstring target, double[] data)
    {
        bool relative = false;
        if(target[$ - 1..$] == "+")
        {
            target = target[0..$-1];
            relative = true;
        }
        spanim(id, spriteAnimTarget[target] | (relative ? SpriteAnimTarget.relative : cast(SpriteAnimTarget)0), data);
        
    }
    static SpriteAnimTarget[wstring] spriteAnimTarget;
    static this()
    {
        spriteAnimTarget = [
            "XY": SpriteAnimTarget.XY,
            "Z": SpriteAnimTarget.Z,
            "UV": SpriteAnimTarget.UV,
            "I": SpriteAnimTarget.I,
            "R": SpriteAnimTarget.R,
            "S": SpriteAnimTarget.S,
            "C": SpriteAnimTarget.C,
            "V": SpriteAnimTarget.V,
        ];
    }
    void spanim(int id, SpriteAnimTarget target, double[] data)
    {
        id = spid(id);
        bool relative;
        if(SpriteAnimTarget.relative & target)
        {
            relative = true;
            target ^= SpriteAnimTarget.relative;
        }
        int animcount = cast(int)data.length / ((target == SpriteAnimTarget.XY || target == SpriteAnimTarget.UV) ? 3 : 2);
        SpriteAnimData[] animdata = new SpriteAnimData[animcount];
        int j;
        int loop = 1;
        SpriteAnimData* old;
        for(int i = 0; i < data.length;)
        {
            i = animdata[j].load(i, sprites[id], target, data, old);
            old = &animdata[j++];
            if(data.length - i == 1)
            {
                //loop
                loop = cast(int)data[i];
                break;
            }
        }
        sprites[id].setAnimation(animdata, target, loop);
    }
    void spclr(int id)
    {
        id = spid(id);
        sprites[id].clear;
    }
    void spclr()
    {
        for(int i = 0; i < sprites.length; i++)
        {
            sprites[i].clear;
        }
    }
    void sphome(int i, int hx, int hy)
    {
        i = spid(i);
        sprites[i].homex = hx;
        sprites[i].homey = hy;
    }
    void spscale(int i, double x, double y)
    {
        i = spid(i);
        sprites[i].scalex = x;
        sprites[i].scaley = y;
    }
    void sprot(int i, double rot)
    {
        i = spid(i);
        sprites[i].r = rot;
    }
    void spcolor(int id, uint color)
    {
        id = spid(id);
        sprites[id].color = petitcom.toGLColor(color);
    }
    void splink(int child, int parent)
    {
        if(parent >= child)
        {
            throw new IllegalFunctionCall("SPLINK");
        }
        parent = spid(parent);
        child = spid(child);
        //SPLINK 2,0
        //SPLINK 2,1した時の挙動謎
        //最後にSPSETした親が優先される->子が親を保持？
        sprites[child].parent = &sprites[parent];
    }
    //再帰的にUNLINKされるのか？
    void spunlink(int id)
    {
        id = spid(id);
        //parent==nullでもエラーでない
        sprites[id].parent = null;
    }
}
