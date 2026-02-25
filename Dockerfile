# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy project file and restore dependencies
COPY src/*.csproj ./src/
RUN dotnet restore ./src/ZavaStorefront.csproj

# Copy remaining source and publish
COPY src/ ./src/
RUN dotnet publish ./src/ZavaStorefront.csproj -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

# Expose port 8080 (default for ASP.NET 8 in containers)
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
