/*
Cleaning Data in SQL Queries
*/

SELECT *
from PortfolioProject2.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------------------------
-- Standardize Date Formate


--Attempting to clean up the SaleDate column
SELECT SaleDate, CONVERT(Date,SaleDate)
FROM PortfolioProject2.dbo.NashvilleHousing

--This isn't working for some reason, alternative option below
UPDATE PortfolioProject2.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

--Creating new column SaleDateConverted and inserting converted SaleDate
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM PortfolioProject2.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------------------------
--Populate Property Address data

SELECT *
FROM PortfolioProject2.dbo.NashvilleHousing
WHERE PropertyAddress is null

SELECT *
FROM PortfolioProject2.dbo.NashvilleHousing
--WHERE PropertyAddress is null
ORDER BY ParcelID

--Joining the table to itself on ParcelID and where UniqueID does not equal each other
--We see PropertyAddress is populating for ParcelID in table two where it is showing null in table one
SELECT one.ParcelID, one.PropertyAddress, two.ParcelID, two.PropertyAddress, ISNULL(one.PropertyAddress, two.PropertyAddress)
FROM PortfolioProject2.dbo.NashvilleHousing one
JOIN PortfolioProject2.dbo.NashvilleHousing two
	on one.ParcelID = two.ParcelID
	AND one.[UniqueID ] <> two.[UniqueID ]
WHERE one.PropertyAddress is null

--Populating null values in table one with PropertyAddress values in table two
UPDATE one
SET PropertyAddress = ISNULL(one.PropertyAddress, two.PropertyAddress)
FROM PortfolioProject2.dbo.NashvilleHousing one
JOIN PortfolioProject2.dbo.NashvilleHousing two
	on one.ParcelID = two.ParcelID
	AND one.[UniqueID ] <> two.[UniqueID ]
WHERE one.PropertyAddress is null

--------------------------------------------------------------------------------------------------------------------------------------------------

--Breaking out Address into Individual Columns (Address, City, State)

--Looking at the data we are going to be cleaning
SELECT PropertyAddress
FROM PortfolioProject2.dbo.NashvilleHousing

--Selecting substrings of the Property Address and labeling them properly
--Using Charindex to go to the column, and -+1 to change position to get rid of the comma
SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
FROM PortfolioProject2.dbo.NashvilleHousing

--Adding two new columns to add the Substrings to
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

--Inserting the Substrings into the new columns
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject2.dbo.NashvilleHousing

--Simpler way to do this with the OwnerAddress

SELECT OwnerAddress
FROM PortfolioProject2.dbo.NashvilleHousing

--It comes out backwards using ascending
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
FROM PortfolioProject2.dbo.NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject2.dbo.NashvilleHousing

--Adding new columns for Parsed data
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);
ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);
ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

--Inserting Parsed data
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


--------------------------------------------------------------------------------------------------------------------------------------------------

--Change Y and N to Yes and No in "Sold as Vacant" field

--Taking a look at the data that we want to clean. We can see that Y and N have much smaller numbers so we will change to Yes and No
SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject2.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--Selecting and changing Y and N to Yes and No using a Case Statement and putting them in a new column to display the change we want
SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
FROM PortfolioProject2.dbo.NashvilleHousing

--Using an Update Statement to push the change through
UPDATE NashvilleHousing
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END

--------------------------------------------------------------------------------------------------------------------------------------------------

--Remove Duplicates. Not a standard practice to delete data thats in a database
--We need to partition by on things that should by unique to each row. 
WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject2.dbo.NashvilleHousing
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1


WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject2.dbo.NashvilleHousing
)
SELECT * 
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--------------------------------------------------------------------------------------------------------------------------------------------------

--Delete unused columns

--Deleting columns that we cleaned up 
ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate

