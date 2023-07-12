/*
Seattle AirBnb Data Cleaning and Exploration 

Dataset: https://www.kaggle.com/datasets/airbnb/seattle

Skills used: Partion by Subclause, Joins, CTE, Temp Tables, String Manipulation, 
			 Creating View, Aggregate Functions, Converting Data Types, Stored Procedure

*/

/****** Cleaning Data  ******/

-- Splitting Street name from Street column

Select 
	Parsename(Replace(street, ',', '.'), 4) as Street_name
From SeattleAirbnbProject.dbo.listings
Where street is not Null

Alter Table SeattleAirbnbProject.dbo.listings
Add street_name NVARCHAR(255)

Update SeattleAirbnbProject.dbo.listings
Set street_name = Parsename(Replace(street, ',', '.'), 4)

Select street_name
From SeattleAirbnbProject.dbo.listings

--- Cleaning list of amenities

Select id, amenities,
	Replace(Replace(Replace(amenities, '"', ''), '{', ''), '}', '') as amenities_cleansed
From SeattleAirbnbProject.dbo.listings

Alter Table SeattleAirbnbProject.dbo.listings
Add amenities_cleansed Nvarchar(700)

Update SeattleAirbnbProject.dbo.listings
Set amenities_cleansed = Replace(Replace(Replace(amenities, '"', ''), '{', ''), '}', '')

Select id, amenities_cleansed
From SeattleAirbnbProject.dbo.listings

--- Count the number of amenities of each listing using Partition By and String_split

With AmenitiesCTE as (
	Select id,
		   Row_number() over (Partition by id Order by id) as row_num,
		   Case
				When amenities_cleansed = '' Then 0
				Else Count(value) over (Partition by id) 
			End as amen_num
	From SeattleAirbnbProject.dbo.listings
		Cross Apply String_split(amenities_cleansed, ',')
)
Select id, amen_num
From AmenitiesCTE
Where row_num = 1

Alter Table SeattleAirbnbProject.dbo.listings
Add amenities_num Int

With AmenitiesCTE as (
	Select id,
		   Row_number() over (Partition by id Order by id) as row_num, 
		   Case
				When amenities_cleansed = '' Then 0
				Else Count(value) over (Partition by id) 
			End as amen_num
	From SeattleAirbnbProject.dbo.listings
		Cross Apply String_split(amenities_cleansed, ',')
)
Update SeattleAirbnbProject.dbo.listings
Set amenities_num = amen_num
From SeattleAirbnbProject.dbo.listings l1
Inner Join AmenitiesCTE l2 On l1.id = l2.id
Where row_num = 1

Select id, amenities_cleansed, amenities_num
From SeattleAirbnbProject.dbo.listings

--- Format price as Decimal

Select id,price
From SeattleAirbnbProject.dbo.listings
Where price like '%,%'

Select id,
	   Cast(Replace(Replace(price, ',', ''), '$', '') as Decimal(10,2)) as price_formatted
From SeattleAirbnbProject.dbo.listings

Alter Table SeattleAirbnbProject.dbo.listings
Add price_formatted Decimal(10,2)

Update SeattleAirbnbProject.dbo.listings
Set price_formatted = Cast(Replace(Replace(price, ',', ''), '$', '') as Decimal(10,2))



/****** Exploring Data  ******/

--- Create Listings View
Create View ListingsView As
SELECT [id]
      ,[name]
      ,[host_id]
      ,[host_name]
      ,[host_since]
      ,[host_neighbourhood]
      ,[host_listings_count]
      ,[host_total_listings_count]
      ,[street_name]
      ,[neighbourhood_cleansed]
      ,[neighbourhood_group_cleansed]
      ,[city]
      ,[state]
      ,[zipcode]
      ,[market]
      ,[country]
      ,[latitude]
      ,[longitude]
      ,[property_type]
      ,[room_type]
      ,[accommodates]
      ,[bathrooms]
      ,[bedrooms]
      ,[beds]
      ,[bed_type]
      ,[amenities_cleansed]
      ,[amenities_num]
      ,[price_formatted]
      ,[guests_included]
      ,[extra_people]
      ,[minimum_nights]
      ,[maximum_nights]
      ,[number_of_reviews]
      ,[review_scores_rating]
      ,[review_scores_accuracy]
      ,[review_scores_cleanliness]
      ,[review_scores_checkin]
      ,[review_scores_communication]
      ,[review_scores_location]
      ,[review_scores_value]
  FROM [SeattleAirbnbProject].[dbo].[listings]

---- Average Price by Zip Codes

Select Distinct(zipcode),
	Cast(Avg(price_formatted) as Decimal(10,2)) as Avg_price_by_Zip
From SeattleAirbnbProject.dbo.listings
Where zipcode <> ''
Group by zipcode
Order by Avg_price_by_Zip Desc

----- Revenue by Month in 2016 using Temp Table and Stored Procedure

Create Procedure RevenueByMonth as
Drop Table If Exists #RevenueByMonth
Create Table #RevenueByMonth(
	ListingID int,
	Month int,
	DailyRevenue Decimal(10,2)
)

Insert Into #RevenueByMonth
Select listing_id,
	Datepart(month, date),
	Cast(Replace(Replace(Replace(price, '"', ''), '$', ''), ',', '') as Decimal(10,2))
From SeattleAirbnbProject.dbo.calendar
Where price <> '' and Datepart(year, date) = 2016

Select Distinct(Month) as [Month of Year],
	Sum(DailyRevenue) over (Partition by Month) as MonthlyRevenue
From #RevenueByMonth
Order by Month

Exec RevenueByMonth	---- Show revenue for all months

Create Procedure RevenueByMonthInput
@month_input int
As
Drop Table If Exists #RevenueByMonth
Create Table #RevenueByMonth(
	ListingID int,
	Month int,
	DailyRevenue Decimal(10,2)
)

Insert Into #RevenueByMonth
Select listing_id,
	Datepart(month, date),
	Cast(Replace(Replace(Replace(price, '"', ''), '$', ''), ',', '') as Decimal(10,2))
From SeattleAirbnbProject.dbo.calendar
Where price <> '' and Datepart(year, date) = 2016

Select Distinct(Month) as [Month of Year],
	Sum(DailyRevenue) over (Partition by Month) as MonthlyRevenue
From #RevenueByMonth
Where Month = @month_input
Order by Month

Exec RevenueByMonthInput @month_input = 5	---- Show revenue for inputed month

-------- Average Price and Revenue by Number of Bedrooms

Drop Table If Exists #PricePerBedrooms
Create Table #PricePerBedrooms (
	BedroomNum	Int,
	Price Decimal(10,2)
)

Insert Into  #PricePerBedrooms
Select bedrooms, 
	Cast(Replace(Replace(Replace(cal.price, '"', ''), '$', ''), ',', '') as Decimal(10,2))
From SeattleAirbnbProject.dbo.listings as list
Inner Join SeattleAirbnbProject.dbo.calendar as cal
On list.id = cal.listing_id
Where cal.price <> ''

Select Distinct(BedroomNum),
	Cast(Avg(Price) over (Partition by BedroomNum) as Decimal(10,2)) as AvgPrice,
	Cast(Count(Price) over (Partition by BedroomNum) as Decimal(10,2)) as Revenue
From #PricePerBedrooms
Order by BedroomNum



