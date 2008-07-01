package Bio::EnsEMBL::GlyphSet::TSE_generic_match;
use strict;
use Bio::EnsEMBL::GlyphSet;
@Bio::EnsEMBL::GlyphSet::TSE_generic_match::ISA = qw(Bio::EnsEMBL::GlyphSet);
use Data::Dumper;
$Data::Dumper::Maxdepth = 3;

sub init_label {
	my ($self) = @_;
	$self->init_label_text();#'Transcript evidence' );
}

sub _init {
	my ($self) = @_;
	my $Config     = $self->{'config'};
	my $h          = 8; #height of glyph

#	my $colours       = $self->colours();
	my $pix_per_bp = $Config->transform->{'scalex'};
	my( $fontname, $fontsize ) = $self->get_font_details( 'outertext' );
	my($font_w_bp, $font_h_bp) = $Config->texthelper->px2bp($fontname);
#	warn Dumper($Config->texthelper);
	
	my $length      = $Config->container_width(); 
	my $all_matches = $Config->{'transcript'}{'transcript_evidence'};
	my $strand      = $Config->{'transcript'}->{'transcript'}->strand;

	my( $font_w_bp, $font_h_bp);

	my $legend_priority = 4;

	my @draw_end_lines;



	#go through each hit (transcript_supporting_feature)
	my $H          = 0;

	foreach my $hit_details (sort { $b->{'hit_length'} <=> $a->{'hit_length'} } values %{$all_matches} ) {
		my $hit_name = $hit_details->{'hit_name'};
		my $start_x  = 1000000;
		my $finish_x = 0;
		my $last_end = 0; #true/false (prevents drawing of line from first exon

		$Config->{'TSE_legend'}{'hit_feature'}{'found'}++;
		$Config->{'TSE_legend'}{'hit_feature'}{'priority'} = $legend_priority;
		$Config->{'TSE_legend'}{'hit_feature'}{'height'} = $h;

		#draw hit locations
		foreach my $block (@{$hit_details->{'data'}}) {
			my $width = $block->[1]-$block->[0] +1;
			$start_x  = $start_x  > $block->[0] ? $block->[0] : $start_x;
			$finish_x = $finish_x < $block->[1] ? $block->[1] : $finish_x;

			my ($w,$x);
			if ($strand == 1) {
				$x = $last_end + (1/$pix_per_bp);
				$w = $block->[0] - $last_end - (1/$pix_per_bp);
			}
			else {
				$x = $last_end;
				$w = $block->[1] - $last_end;
			}

			if ($last_end) {
				my $G = new Sanger::Graphics::Glyph::Line({
					'x' => $x,
					'y' => $H + $h/2,
					'h'=>1,
					'width'=> $w,
					'colour'=>'black',
					'absolutey'=>1,});
				#add a red attribute if there is a part of the hit missing
				if (my $mismatch = $block->[5]) {
					$G->{'dotted'} = 1;
					$G->{'colour'} = 'red';
					$G->{'title'} = $mismatch > 0 ? "Missing $mismatch bp of hit" : "Overlapping ".abs($mismatch)." bp of hit";
				}
				$self->push($G);				
			}

			$last_end = $strand == 1 ? $block->[1] : $block->[0];
#			warn "hit = $hit_name: x = ",$block->[0]," width = $width";

			my $G = new Sanger::Graphics::Glyph::Rect({
				'x'         => $block->[0] ,
				'y'         => $H,
				'width'     => $width,
				'height'    => $h,
				'bordercolour' => 'black',
				'absolutey' => 1,
				'title'     => $hit_name,
				'href'      => '',
			});		

			#second and third elements of $block define whether there is a mismatch between exon and hit boundries
			#(need some logic to add meaningfull terms to zmenu)
			if ($block->[3]) {
				my $c = $block->[3] > 0 ? 'red' : 'blue';
				push @draw_end_lines, [$block->[0],$H,$c];
				push @draw_end_lines, [$block->[0]+1/$pix_per_bp,$H,$c];
				
				$G->{'title'} = $hit_name." (".$block->[3].")";
			}
			if ($block->[4]) {
				my $c = $block->[4] > 0 ? 'red' : 'blue';
				push @draw_end_lines, [$block->[1]-1/$pix_per_bp,$H,$c];
				push @draw_end_lines, [$block->[1],$H,$c];
				$G->{'title'} = $hit_name." (".$block->[4].")";
			}
			$self->push( $G );
		}

		#draw extensions at the left of the image
#		if (   ($hit_details->{'start_extension'} && $strand == 1)
#			|| ($hit_details->{'end_extension'} && $strand == -1)) {
#			$self->push(new Sanger::Graphics::Glyph::Line({
#				'x'         => 0,
#				'y'         => $H + 0.5*$h,
#				'width'     => $start_x,
#				'height'    => 0,
#				'absolutey' => 1,
#				'colour'    => 'blue',
#			}));
#		}
#		#draw extensions at the right of the image
#		if (   ($hit_details->{'end_extension'} && $strand == 1)
#			|| ($hit_details->{'start_extension'} && $strand == -1)) {
#			warn "x = $finish_x";
#			$self->push(new Sanger::Graphics::Glyph::Line({
#				'x'         => $finish_x + (1/$pix_per_bp),
#				'y'         => $H + 0.5*$h,
#				'width'     => $length-$finish_x,
#				'height'    => 0,
#				'absolutey' => 1,
#				'colour'    => 'blue',
#			}));
#		}			 

		my @res = $self->get_text_width(0, "$hit_name", '', 'font'=>$fontname, 'ptsize'=>$fontsize);
		my $W = ($res[2])/$pix_per_bp;
		($font_w_bp, $font_h_bp) = ($res[2]/$pix_per_bp,$res[3]);

		my $tglyph = new Sanger::Graphics::Glyph::Text({
			'x'         => -$res[2],
			'y'         => $H,
			'height'    => $font_h_bp,
			'width'     => $res[2],
			'textwidth' => $res[2],
			'font'      => $fontname,
			'colour'    => 'blue',
			'text'      => $hit_name,
			'absolutey' => 1,
			'absolutex' => 1,
			'absolutewidth' => 1,
			'ptsize'    => $fontsize,
			'halign     '=> 'right',
		});
		$self->push($tglyph);

		$H += $font_h_bp + 4;
	}

	#draw lines for the exon / hit boundry mismatches (draw last so they're on top of everything else)
	foreach my $mismatch_line ( @draw_end_lines ) {
		my $G = new Sanger::Graphics::Glyph::Line({
			'x'         => $mismatch_line->[0] ,
			'y'         => $mismatch_line->[1],
			'width'     => 0,
			'height'    => $h,
			'colour'    => $mismatch_line->[2],
			'absolutey' => 1,
		});
		$self->push( $G );
	}
}

1;
