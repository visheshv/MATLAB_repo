function idx = find_closest_momentum_star_strategy1(star_positions_target,star_velocities_target,x0,n,star_ID,x,y,z)

% Define initial states
r0 =  x0(1:3);
v0= x0(4:6);

gen_jump=0;% kpc
min_sep=1;% minimum separation allowed for the target stars from any of the settled stars

% remove stars under or outside the sphere of radius norm(r0)
% condition=vecnorm((star_positions_target)')' >  norm(r0)+gen_jump;
% star_positions_target(condition,:)= repmat([inf inf inf], sum(condition),1 );

star_id_settled = star_ID(star_ID~=0); % IDs for settled stars

if ~isempty(star_id_settled)
%     settled_star_pos_temp=star_positions_target(star_id_settled,1:3);       % temporary matrix to store settled star positions
    settled_star_pos_temp=[x(star_id_settled+1,181) y(star_id_settled+1,181) z(star_id_settled+1,181)];       % temporary matrix to store settled star positions at tf =90 myr
    star_positions_target(star_id_settled,1:3)= repmat([inf inf inf],length(star_id_settled),1);
end

% Identify 'n' closest stars
idx = knnsearch(star_positions_target,r0','K',10000);          
% idx_low = knnsearch(star_positions_target,r0','K',300);
% idx = setdiff(idx_up,idx_low);

rel_pos= star_positions_target(idx,:)-repmat(r0',length(idx),1);
normvec= vecnorm((rel_pos)')';
rel_pos= rel_pos./normvec;
rel_vel= star_velocities_target(idx,:)-repmat(v0',length(idx),1);
normvel= vecnorm((rel_vel)')';

v_n= repmat(v0'/norm(v0),length(idx),1);

angles = acosd(dot(rel_pos,v_n,2));
sign_data=angle_sign(rel_pos,v_n,repmat(r0',length(idx),1));

if ~isempty(star_id_settled)
    for j=1:length(idx)
        r_j = [x(idx(j)+1,181),y(idx(j)+1,181),z(idx(j)+1,181)];
        idx_temp= knnsearch(settled_star_pos_temp,r_j,'K',1);
        dist_min=norm(settled_star_pos_temp(idx_temp,:)-r_j);
        if dist_min < min_sep
            angles(j) = 179;
        end
    end
end
        

% Find the highest frequency of them in the direction of the current velocity
% hist=histogram(normvec);[~,i_r_min]=max(hist.Values);
% r_min=hist.BinEdges(i_r_min);
% stats for short tof transfers

r_max=4;
r_min=1.2;
v_max=0.3;

inc_thresh=3; % inclination range

% plane normal
h=cross(star_positions_target(idx,:),star_velocities_target(idx,:));
h=h./vecnorm((h)')';
inc=acosd(dot(h,repmat([0 0 -1],length(idx),1),2));

angles(normvec<r_min)=repmat(179, sum(normvec<r_min),1 ); % remove the very close stars from contention by making the angle values to be 179
angles(normvec>r_max)=repmat(179, sum(normvec>r_max),1 ); % remove the very close stars from contention by making the angle values to be 179
angles(normvel>v_max)=repmat(179, sum(normvel>v_max),1 ); % remove the very close stars from contention by making the angle values to be 179
angles(inc>inc_thresh)=repmat(179, sum(inc>inc_thresh),1); % remove the very close stars from contention by making the angle values to be 179

if n==1
    
    [tempA,i_angles]=sort(angles);
    
    if tempA(1)==179
        disp('break')
    end
    
    idx=idx(i_angles);
    idx=idx(1:n);

else

%     [tempA,i_angles]=sort(angles);idx=idx(i_angles); idx=idx(1:n);
    
    angles_temp =  angles .* sign_data;
       
    [~,ind_min]=min(abs(angles_temp));
    idx1=idx(ind_min);
    
    [tempA,i_angles]=sort(angles_temp);
    i_1= find( (tempA> (1.1 * (180/pi))) & (tempA< (179 )));
    
    if isempty(i_1)
        cond1=0;
    else
        cond1=1;
        idx2=idx(i_angles(i_1(1)));
    end
    
    i_2= find( (tempA< (-1.1 * (180/pi))) & (tempA> (-179)));
    
    if isempty(i_2)
        cond2=0;
    else
        cond2=1;
        idx3=idx(i_angles(i_2(end)));
    end
    
    if cond1==0 && cond2==1
        idx=[idx1;idx3];
    elseif cond1==1 && cond2==0
        idx=[idx1;idx2];
    elseif cond1==0 && cond2==0
        idx=idx1;
    elseif cond1==1 && cond2==1
        idx=[idx1;idx2;idx3];
    end
    
    %1.1 radian gives segment length greater than 1 kpc for r_min =1 kpc
    
end

% Check:
% plot3(settled_star_pos_temp(:,1),settled_star_pos_temp(:,2),settled_star_pos_temp(:,3),'o');
% hold on; plot3(x(idx+1,181),y(idx+1,181),z(idx+1,181),'.'); hold on; plot3(x(idx+1,181),y(idx+1,181),z(idx+1,181),'*')
% plot3(star_positions_target(idx,1),star_positions_target(idx,2),star_positions_target(idx,3),'.')
% hold on; plot3(star_positions_target(idx,1),star_positions_target(idx,2),star_positions_target(idx,3),'*')
