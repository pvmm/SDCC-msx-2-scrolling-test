clear
close all

      %  green red blue
t =   [ 0 0 0
        0 0 2
        0 3 0
        0 3 2
        3 0 0
        3 0 2
        3 3 0
        3 3 2
        4 7 2
        0 0 7
        0 7 0
        0 7 7
        7 0 0
        7 0 7
        7 7 0
        7 7 7];
        


sprtpalrgb = t(:,[2 1 3])/7;

        
figure;
r = uint8(kron(0:15,ones(16,1)));
t = bitor(r,r');
t = imresize(t,sprtpalrgb,16,'nearest', 'Colormap','original');
image(t)
colormap(sprtpalrgb);
axis equal
grid
imwrite(t,sprtpalrgb,'grpx\spritepalette.png','png', 'BitDepth',8)


name = 'linktest';

%[AA,MAP] = imread([name '_gold.png']);
%[AA,MAP] = imread([name '_silver.png']);
[AA,MAP] = imread([name '.png']);

sprtpalrgb = [ sprtpalrgb ; MAP(17,:)];         % 17 transparent
%sprtpalrgb = [sprtpalrgb ; ones(240,3)]

Y = AA;
figure
image(Y)
axis equal
colormap(MAP)

Y = Y(1:32,1:192);

Frames = im2col(Y,[32 16],'distinct');

[C,IA,IC] = unique(Frames','rows');

CC = C';
A = col2im( CC,[32 16],[32 size(CC,2)*16],'distinct');

[LIA,LOCB] = ismember(Frames',C,'rows');

figure
image(A)
axis equal
colormap(MAP)

imwrite(A,MAP,['grpx\' name '_shapes.png'],'png', 'BitDepth',8)

IC = LOCB;

fid = fopen([name '_ani.asm'],'w');
fprintf (fid,[name '_ani:\n']);
fprintf (fid,'    defb %d \n',IC-1);
fclose(fid);

Y = A;
Nframes = size(CC,2);

frame1 = cell(32,Nframes);
frame2 = cell(32,Nframes);
color1 = cell(32,Nframes);
color2 = cell(32,Nframes);

figure
axis equal
colormap(MAP)

k = 0;
h = 0;
Template = [];
for i = 1:Nframes
    img = Y(h+(1:32),k+(1:16));
    image(img);
    drawnow;
    i
    for j = 1:32
        line = double(img(j,:))+1;
        [s1,s2,c1,c2] = convert_line2(line,MAP,sprtpalrgb);
        frame1{j,i} = s1;
        frame2{j,i} = s2;
        color1{j,i} = c1;
        color2{j,i} = c2;
    end
    
    Template = [Template img];
    
    k = k + 16;
    if (k>=size(Y,2))
        k = 0;
        h = h + 32;
    end
end
imwrite(Template,MAP,['grpx\' name '_org.png'],'png', 'BitDepth',8)

org = MAP(1+Template);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save converted sprite data
k = 0;
h = 0;
YY = Y;

for i = 1:Nframes
    img = zeros(32,16);
    for j = 1:32
        line = bitor(frame1{j,i}*color1{j,i}, frame2{j,i}*bitand(color2{j,i},15));
        line(bitand(frame1{j,i}==0,frame2{j,i}==0)) = 16;                     % transparent
        img(j,:) = line;
    end
    YY(h+(1:32),k+(1:16)) = img ;

    k = k + 16;
    if (k>=size(YY,2))
        k = 0;
        h = h + 32;
    end
end
imwrite(YY,sprtpalrgb,['grpx\' name '_scr8.png'],'png', 'BitDepth',8)

imwrite(abs(org-sprtpalrgb(1+YY)),['grpx\' name '_comp.bmp'],'bmp')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save sprite data


fid = fopen([name '_frm.bin'],'w');
fid2 = fopen([name '_clr.bin'],'w');

for i = 1:Nframes
    for j = 1:16
        s = frame1{j,i};
        t = dec2hex(bi2de(s(1:8),'left-msb'),2);
        fwrite (fid,hex2dec(t));
    end
    for j = 1:16
        s = frame1{j,i};    
        t = dec2hex(bi2de(s(9:16),'left-msb'),2);
        fwrite (fid,hex2dec(t));
    end
    
    for j = 1:16
        s = frame2{j,i};
        t = dec2hex(bi2de(s(1:8),'left-msb'),2);
        fwrite (fid,hex2dec(t));
    end
    for j = 1:16
        s = frame2{j,i};    
        t = dec2hex(bi2de(s(9:16),'left-msb'),2);
        fwrite (fid,hex2dec(t));
    end
    
    for j = 17:32
        s = frame1{j,i};
        t = dec2hex(bi2de(s(1:8),'left-msb'),2);
        fwrite (fid,hex2dec(t));
    end
    for j = 17:32
        s = frame1{j,i};    
        t = dec2hex(bi2de(s(9:16),'left-msb'),2);
        fwrite (fid,hex2dec(t));
    end
    
    for j = 17:32
        s = frame2{j,i};
        t = dec2hex(bi2de(s(1:8),'left-msb'),2);
        fwrite (fid,hex2dec(t));
    end
    for j = 17:32
        s = frame2{j,i};    
        t = dec2hex(bi2de(s(9:16),'left-msb'),2);
        fwrite (fid,hex2dec(t));
    end
    
    for j = 1:16
        s = color1{j,i};
        fwrite (fid2,s);
    end
    for j = 1:16
        s = color2{j,i};
        fwrite (fid2,s);
    end
    for j = 17:32
        s = color1{j,i};
        fwrite (fid2,s);
    end
    for j = 17:32
        s = color2{j,i};
        fwrite (fid2,s);
    end
end
fclose(fid);
fclose(fid2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save collision window

minx = zeros(Nframes,1);
maxx = zeros(Nframes,1);
miny = zeros(Nframes,1);
maxy = zeros(Nframes,1);

h = 1;
kk = 0;
for i = 1:Nframes
    A = Y((1:32),kk+(1:16)) ~= 16;              % transparent
    for x = 1:16
        if any(A(:,x))
            minx(h) = x;
            break;
        end
    end
    for x = 16:-1:1
        if any(A(:,x))
            maxx(h) = x;
            break;
        end
    end
    for x = 1:32
        if any(A(x,:))
            miny(h) = x;
            break;
        end
    end
    for x = 32:-1:1
        if any(A(x,:))
            maxy(h) = x;
            break;
        end
    end
    %[h minx(h) maxx(h) miny(h) maxy(h)]
    h = h + 1;
    kk = kk + 16;
end

fid = fopen([name '_frm_coll_wind.asm'],'w');
fprintf (fid,[name '_coll_wind:\n']);
for h = 1:size(Y,2)/16
     fprintf (fid,'    defb %d,%d,%d,%d \n',[minx(h) maxx(h)-1 miny(h) maxy(h)-1] );
end
fprintf (fid,'\n');
fclose(fid);
