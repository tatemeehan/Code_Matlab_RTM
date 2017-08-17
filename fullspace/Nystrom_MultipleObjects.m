function U=Nystrom_MultipleObjects(n, n_src, n_recv, bctype,wavenumber, source,receiver)
%%  source: positon of source
%% receive: position of receive

%% compute the quadrature weights;
w = quad_weights(n);
R = zeros(2*n);

for k=1:2*n
     idx=[k:2*n];
     R(idx,k)=w([1:2*n-k+1]);
     R(k,k)=R(k,k)/2;  %% for convinience
end
R=(R+R');
%% discrete point
node = 0:2*n-1;
t = pi*node(:)/n;

Mat = zeros(2*n*2,2*n*2);
gap =  3;
rs=2;rt=2;
for num=1:2
    
    if num==1
        [x1,x2]=circlebc(t,1);   
        [dx1,dx2]=circlebc(t,2);
        [ddx1,ddx2]=circlebc(t,3);
        x1=x1*rs-gap;
        x2=x2*rs-gap;
        dx1=dx1*rs;dx2=dx2*rs;
        ddx1=ddx1*rs;ddx2=ddx2*rs;
    else
        [x1,x2]=circlebc(t,1);  
        [dx1,dx2]=circlebc(t,2);
        [ddx1,ddx2]=circlebc(t,3);
        x1=x1/rt + gap;
        x2=x2/rt + gap;
        dx1=dx1/rt;dx2=dx2/rt;
        ddx1=ddx1/rt;ddx2=ddx2/rt;
%          [x1,x2]=kite(t,1);   
%          x1=x1+6;
%          x2=x2+5;
%         [dx1,dx2]=kite(t,2);
%         [ddx1,ddx2]=kite(t,3);
    end

    r = zeros(2*n);

    for k=1:2*n
        for j=1:2*n
            r(k,j)=sqrt((x1(j)-x1(k))* (x1(j)-x1(k))+(x2(j)-x2(k))* (x2(j)-x2(k)));
        end
    end

    L1 = zeros(2*n);
    M1 = zeros(2*n);
    L2 = zeros(2*n);
    M2 = zeros(2*n);
    Ceuler = 0.577215665;
    distance = sqrt( dx1.*dx1+dx2.*dx2 );

    for j=1:2*n
        for k=1:2*n
        if (j==k)
            dist = distance(k);
            M1(j,k) = -1/(2*pi)*besselj(0,wavenumber*r(j,k))*dist;
            L2(j,k) = 1/(2*pi)*(dx1(j)*ddx2(j)-dx2(j)*ddx1(j))/(dist*dist);
            M2(j,k) = (i/2-Ceuler/pi-1/(2*pi)*log(wavenumber^2/4*dist*dist))*dist;
        else
            dist = distance(k);
            temp = dx2(k)*(x1(j)-x1(k))-dx1(k)*(x2(j)-x2(k));
            
            L1(j,k) = wavenumber/(2*pi)*temp*besselj(1,wavenumber*r(j,k))/r(j,k);
            L2(j,k) = i*wavenumber/2*(-temp)*besselh(1,wavenumber*r(j,k))/r(j,k) - L1(j,k)*log(4*sin((t(j)-t(k))/2)^2);
            M1(j,k) = -1/(2*pi)*besselj(0,wavenumber*r(j,k))*dist;
            M2(j,k) = i/2*besselh(0,wavenumber*r(j,k))*dist - M1(j,k)*log(4*sin((t(j)-t(k))/2)^2);
        end
        end
    end
%% the linear System is A = I-(L1+ik*M1 +pi/n*(L2+ik*M2))

    eta = wavenumber; 
    A=eye(2*n) - (R.*(L1+i*eta*M1)+pi/n*(L2+i*eta*M2));
    if num==1
        Mat(1:2*n,1:2*n)=A;
    else
        Mat(2*n+1:end,2*n+1:end) = A;
    end
    
    for is=1:n_src
        f(1+2*n*(num-1):2*n*num,is) = -2*Green(wavenumber, source(:,is)*ones(1,2*n),[x1';x2']);
    end
end


 [x1,x2]=circlebc(t,1);    %% the first object
 x1=x1-gap;
 x2=x2-gap;
 [dx1,dx2]=circlebc(t,2);
 
%  [x1,x2]=circlebc(t,1);  
%   x1=x1+gap;
%  [dx1,dx2]=circlebc(t,2);
 
% [y1,y2]=kite(t,1);        %% the second object
% y1=y1+6;
% y2=y2+5;
%  [dy1,dy2]=kite(t,2);

        [y1,y2]=circlebc(t,1);  
        [dy1,dy2]=circlebc(t,2);
        y1=y1/rt + gap;
        y2=y2/rt + gap;
        dy1=dy1/rt;dy2=dy2/rt;
 
 A12=zeros(2*n);
 A21=zeros(2*n);
 distancex = sqrt(dx1.^2+dx2.^2);
 distancey = sqrt(dy1.^2+dy2.^2);
 
 for k=1:2*n
   
     g1 = Green(wavenumber,[x1(k);x2(k)]*ones(1,2*n),[y1';y2']);
     gd1 = Green_Grad(wavenumber, [x1(k);x2(k)]*ones(1,2*n),[y1';y2']);
     temp = pi/n*( (gd1(1,:).*dy2' - gd1(2,:).*dy1') - (1i* eta*distancey').*g1);
     A12(k,:) = temp;
 end
  
  for k=1:2*n
     g1 = Green(wavenumber,[y1(k);y2(k)]*ones(1,2*n),[x1';x2']);
     gd1 = Green_Grad(wavenumber,[y1(k);y2(k)]*ones(1,2*n),[x1';x2']);
     temp = pi/n*( (gd1(1,:).*dx2' - gd1(2,:).*dx1') - (1i* eta*distancex').*g1);
     A21(k,:) = temp;
  end
 Mat(1:2*n,2*n+1:end)=A12;
 Mat(2*n+1:end,1:2*n)=A21;
     
%% the right hand side is double of incidient 

%% 

%% the solution is the potential on the boundary of D
phi = Mat\f;

%% Composite Trapzitol Formula for Computing Far fields pattern

U = zeros(n_recv,n_src);
for j=1:n_src
    for k=1:n_recv
       
        g1   = Green(wavenumber,      receiver(:,k)*ones(1,2*n), [x1';x2']);
        gd1  = Green_Grad(wavenumber, receiver(:,k)*ones(1,2*n), [x1';x2']);
        temp1 = ( (gd1(1,:).*dx2' - gd1(2,:).*dx1') - (1i* eta*distancex').*g1)*phi(1:2*n,j);
        
        g1  = Green(wavenumber,     receiver(:,k)*ones(1,2*n), [y1';y2']);
        gd1 = Green_Grad(wavenumber,receiver(:,k)*ones(1,2*n), [y1';y2']);
        temp2 = ( (gd1(1,:).*dy2' - gd1(2,:).*dy1') - (1i* eta*distancey').*g1)*phi(2*n+1:end,j);
        U(k,j)=pi/n*(temp1+temp2);
    end
end