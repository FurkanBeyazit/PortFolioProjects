--CLEANING DATA with SQL QUERIES
Select *
From PortfolioProject..NashvilleHousing

--Standardized Date Formats

Select SaleDate,CONVERT(Date,Saledate)
From PortfolioProject..NashvilleHousing

ALTER table NasvilleHousing
ADD SaleDateConverted date

Update NashvilleHousing
Set SaledateConverted =CONVERT(date,Saledate)

Select SaleDate,SaleDateConverted
From PortfolioProject..NashvilleHousing

-- Populate Property Address Data

Select *
From PortfolioProject..NashvilleHousing
Where PropertyAddress is  null

Select a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress,ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
on a.ParcelID=b.ParcelID 
and a.[UniqueID ]<>b.[UniqueID ]
where a.PropertyAddress is null

Update a
set PropertyAddress= ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
on a.ParcelID=b.ParcelID 
and a.[UniqueID ]<>b.[UniqueID ]
where a.PropertyAddress is null

--Breaking out  Address into individual columns (Address,City,State) SPLIT--

Select PropertyAddress
From PortfolioProject..NashvilleHousing
--Where PropertyAddress is  null


Select
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,len(PropertyAddress)) as Address
From PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
Set PropertySplitAddress =SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)


ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

Update NashvilleHousing
Set PropertySplitCity =SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,len(PropertyAddress)) 

Select PropertySplitAddress,PropertySplitCity
From PortfolioProject..NashvilleHousing


Select OwnerAddress
From PortfolioProject..NashvilleHousing

Select 
PARSEname(Replace(OwnerAddress,',','.'),3),
PARSEname(Replace(OwnerAddress,',','.'),2),
PARSEname(Replace(OwnerAddress,',','.'),1)
From PortfolioProject..NashvilleHousing


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
Set OwnerSplitAddress =PARSEname(Replace(OwnerAddress,',','.'),3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
Set OwnerSplitCity =PARSEname(Replace(OwnerAddress,',','.'),2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

Update NashvilleHousing
Set OwnerSplitState =PARSEname(Replace(OwnerAddress,',','.'),1)



Select OwnersplitAddress,OwnerSplitCity ,OwnerSplitState
From PortfolioProject..NashvilleHousing


--Change Y and N to Yes and No in "Sold in Vacant" field

Select Distinct(SoldAsVacant),Count(SoldasVacant)
From PortfolioProject..NashvilleHousing
Group by SoldasVacant
order by 2



Select SoldAsVacant,
Case when SoldAsVacant='Y' THEN 'Yes'
	when SoldAsVacant='N' Then 'No'
	Else SoldAsVacant
	end
From PortfolioProject..NashvilleHousing



Update NashvilleHousing 
SET SoldAsVacant= Case when SoldAsVacant='Y' THEN 'Yes'
	when SoldAsVacant='N' Then 'No'
	Else SoldAsVacant
	end



--Removing Duplicates
WITH RowNumCTE as(
Select *,
		row_number() over(
		Partition by ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
		ORDER BY UniqueID
		) row_num

From PortfolioProject..NashvilleHousing
)
Select * 
From RowNumCTE
where row_num>1




WITH RowNumCTE as(
Select *,
		row_number() over(
		Partition by ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
		ORDER BY UniqueID
		) row_num

From PortfolioProject..NashvilleHousing
)
DELETE 
From RowNumCTE
where row_num>1


-- Delete Unused Columns

Select * 
From PortfolioProject..NashvilleHousing

ALTER table PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress,TaxDistrict,PropertyAddress

ALTER table PortfolioProject..NashvilleHousing
DROP COLUMN SaleDate
