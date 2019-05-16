/*Formats for variables to create descriptive statistics*/
proc format;
	value ageband
		15 - 25 = '1. 15 to 25'
		26 - 35 = '2. 26 to 35'
		36 - 45 = '3. 36 to 45'
		46 - 55 = '4. 46 to 55'
		56 - 65 = '5. 56 to 65'
		66 - high ='6. 66 and older'
		other ='7. Other'
	;
	value hundred 
		0 - 25 = '1. 0 to 25'
		26 - 50 = '2. 26 to 50'
		51 - 75 = '3. 51 to 75'
		76 - 100 = '4. 76 to 100'
		other ='5. Other'
	;

	/* Vinay- added this 13 June 2018 for handling formatting for dependent children, 
	nuclei in household and discrimination status.
	 10 Oct 2018 : Changed 77 to "other" in depchild and depchildind*/
	value depchild
		1 = '1. One Dependent child'
		2 = '2. Two Dependent children'
		3 = '3. Three Dependent children'
		4 = '4. Four or more Dependent children'
		5 = '5. No Dependent children'
		other = '6. Unknown number of Dependent children';

	value depchildind
		1 - 4 = '1. Dependent children'
		5 = '2. No Dependent children'
		other = '3. Unknown';

	value hhnucleus
		1 = '1. One Nucleus'
		2 = '2. Two Nuclei'
		3 = '3. Three or more nuclei'
		other = '4. Unknown nuclei';

	value $discrim
		'01' = '1. Experienced Discrimination'
		'02' = '2. Did not experience Discrimination'
		other = '3. Unknown';

	value income
		low -  < 0 = '1. Less than 0'
		0 = '2. 0'
		0.01 - < 4000 = '3. More than 0 Less Than 4000'
		4000 - < 8000 = '4. More than 4000 Less Than 8000'
		8000 - < 12000 = '4. More than 8000 Less Than 12000'
		12000 - high  = '5. 12000 and More'
		other ='6. Other';

	value hospital
		low -  < 0 = '1. Less than 0 '
		0 = '2. 0 '
		0.01 - < 4 = '3. More than 0 Less Than 4'
		4 - < 8 = '4. More than 4 Less Than 8'
		8 - high  = '5. 8 and More'
		other ='6. Other';

	value pharms 
		low -  < 0 = '1. Less than 0 '
		0 = '2. 0 '
		0.01 - < 30 = '3. More than 0 Less Than 30'
		30 - < 100 = '4. More than 30 Less Than 100'
		100 - high  = '5. 100 and More'
		other ='6. Other'
	;
	value elsi 
		low -  < 14 = '1. Less than 14 '
		14 - < 21 = '2. More than 14 Less Than 21'
		21 - < 26 = '3. More than 21 Less Than 26'
		26 - high  = '4. 26 and More'
		other ='5. Other'
	;
	value elsii 
		low -  < 6 = '1. Less than 6 '
		6 - < 14 = '2. More than 6 Less Than 14'
		14 - high  = '4. 14 and More'
		other ='5. Other'
	;
	value tertiary
		low -  < 0 = '1. Less than 0 '
		0 = '2. 0 '
		0.01 - < 40 = '3. More than 0 Less Than 40'
		40 - high  = '4. 40 and More'
		other ='5. Other'
	;
	value dur
		low -  < 0 = '1. Less than 0 '
		0 = '2. 0 '
		0.01 - < 40 = '3. More than 0 Less Than 40'
		40 - < 160  = '4. More than 40 Less Than 160'
		160 - high  = '5. 160 and More'
		other ='6. Other'
	;

	value accom_binary
		low -  0 = 'No Accom. Supplement '
		0.01 - high = 'On Accom. Supplement '	;

	value empwork
		0						='1. 0  '
		1 - 20							 ='2. 1 to 20 '
		21 - 39							 ='3. 21 to 39 '
		40 - 44							 ='4. 40 to 44 '
		45 - 54							 ='5. 45 to 54'
		55 - 99 						='6. 56 to 99'
		other 							='7. Other or NULLS'

	;

	/* Adding a new format for housing status, children dependents and benefit duration as requested for by David Rea, 28 May 2018*/
	value $rentingstatus  
		'HOUSING NZ'			='1. Public-Rent'
		'OTHER SOCIAL HOUSING'	='1. Public-Rent'
		'OWN'					 ='2. Own'
		'TRUST'					='2. Own'
		other 					='3. Private-Rent'


	;
	value $children
		'Couple with dependent child(ren) under 18 only','Couple with adult child(ren) and dependent child(ren) under 18',
		'One parent with adult child(ren) and dependent child(ren) under 18','One parent with dependent child(ren) under 18 only'
			='1. Has Dependent Child(ren)'
		other = '2. Doesnt Have Dependent Child(ren)'

	;
	value ben
		low -  < 0.5 = '1. Less Than 183 days on Benefit in Last Year'
		0.5 - high = '2. More Than 183 days on Benefit in Last Year'
		other = '3. other'
	;

	value $region
	'01'	='Northland Region'
'02'	='Auckland Region'
'03'=	'Waikato Region'
'04'	='Bay of Plenty Region'
'05'	='Gisborne Region'
'06'	='Hawkes Bay Region'
'07'	='Taranaki Region'
'08'	='Manawatu - Wanganui Region'
'09'	='Wellington Region'
'12'	='West Coast Region'
'13'	='Canterbury Region'
'14'	='Otago Region'
'15'	='Southland Region'
'16'	='Tasman Region'
'17'	='Nelson Region'
'18'	='Malborough Region'
other = 'Other Region';

run;