using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Dub.Infrastructure.Database.Models;

namespace Dub.Infrastructure.Database
{
    public partial class DubContext : DbContext
    {
        public DubContext()
        {
        }

        public DubContext(DbContextOptions<DubContext> options)
            : base(options)
        {
        }

        public virtual DbSet<Parameter> Parameters { get; set; }
        public virtual DbSet<ProcessStep> ProcessSteps { get; set; }
        public virtual DbSet<ProcessStepResolution> ProcessStepResolutions { get; set; }
        public virtual DbSet<Product> Products { get; set; }
        public virtual DbSet<ProductClass> ProductClasses { get; set; }
        public virtual DbSet<ProductParameter> ProductParameters { get; set; }
        public virtual DbSet<RunnableProcess> RunnableProcesses { get; set; }
        public virtual DbSet<StartedProcess> StartedProcesses { get; set; }
        public virtual DbSet<Unit> Units { get; set; }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see http://go.microsoft.com/fwlink/?LinkId=723263.
                optionsBuilder.UseNpgsql("Host=localhost;Database=dub;Port=5433;Username=postgres;Password=postgres");
            }
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.HasAnnotation("Relational:Collation", "en_US.utf8");

            modelBuilder.Entity<Parameter>(entity =>
            {
                entity.ToTable("parameters");

                entity.HasIndex(e => e.Name, "parameters_name_uindex")
                    .IsUnique();

                entity.Property(e => e.Id).HasColumnName("id");

                entity.Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(100)
                    .HasColumnName("name");

                entity.Property(e => e.UnitId).HasColumnName("unit_id");

                entity.HasOne(d => d.Unit)
                    .WithMany(p => p.Parameters)
                    .HasForeignKey(d => d.UnitId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("parameters_units_id_fk");
            });

            modelBuilder.Entity<ProcessStep>(entity =>
            {
                entity.ToTable("process_steps");

                entity.Property(e => e.Id).HasColumnName("id");

                entity.Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(100)
                    .HasColumnName("name");
            });

            modelBuilder.Entity<ProcessStepResolution>(entity =>
            {
                entity.ToTable("process_step_resolutions");

                entity.HasIndex(e => new { e.CurrentStepId, e.NextStepId }, "process_step_resolutions_step_in_id_step_out_id_uindex")
                    .IsUnique();

                entity.Property(e => e.Id).HasColumnName("id");

                entity.Property(e => e.CurrentStepId).HasColumnName("current_step_id");

                entity.Property(e => e.NextStepId).HasColumnName("next_step_id");

                entity.Property(e => e.ResolutionText)
                    .IsRequired()
                    .HasMaxLength(100)
                    .HasColumnName("resolution_text");

                entity.HasOne(d => d.CurrentStep)
                    .WithMany(p => p.ProcessStepResolutionCurrentSteps)
                    .HasForeignKey(d => d.CurrentStepId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("process_step_resolutions_process_steps_id_fk");

                entity.HasOne(d => d.NextStep)
                    .WithMany(p => p.ProcessStepResolutionNextSteps)
                    .HasForeignKey(d => d.NextStepId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("process_step_resolutions_process_steps_id_fk_2");
            });

            modelBuilder.Entity<Product>(entity =>
            {
                entity.ToTable("products");

                entity.Property(e => e.Id)
                    .HasColumnName("id")
                    .HasDefaultValueSql("nextval('product_id_seq'::regclass)");

                entity.Property(e => e.BaseId).HasColumnName("base_id");

                entity.Property(e => e.ClassId).HasColumnName("class_id");

                entity.Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(100)
                    .HasColumnName("name");

                entity.Property(e => e.Version)
                    .IsRequired()
                    .HasMaxLength(50)
                    .HasColumnName("version")
                    .HasDefaultValueSql("'1'::character varying");

                entity.HasOne(d => d.Class)
                    .WithMany(p => p.Products)
                    .HasForeignKey(d => d.ClassId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("product_product_classes_id_fk");
            });

            modelBuilder.Entity<ProductClass>(entity =>
            {
                entity.ToTable("product_classes");

                entity.Property(e => e.Id).HasColumnName("id");

                entity.Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(100)
                    .HasColumnName("name");

                entity.Property(e => e.ParentId).HasColumnName("parent_id");
            });

            modelBuilder.Entity<ProductParameter>(entity =>
            {
                entity.HasKey(e => new { e.ProductId, e.ParameterId })
                    .HasName("product_parameters_pk");

                entity.ToTable("product_parameters");

                entity.Property(e => e.ProductId).HasColumnName("product_id");

                entity.Property(e => e.ParameterId).HasColumnName("parameter_id");

                entity.HasOne(d => d.Parameter)
                    .WithMany(p => p.ProductParameters)
                    .HasForeignKey(d => d.ParameterId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("product_parameters_parameters_id_fk");

                entity.HasOne(d => d.Product)
                    .WithMany(p => p.ProductParameters)
                    .HasForeignKey(d => d.ProductId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("product_parameters_products_id_fk");
            });

            modelBuilder.Entity<RunnableProcess>(entity =>
            {
                entity.ToTable("runnable_processes");

                entity.Property(e => e.Id)
                    .HasColumnName("id")
                    .HasDefaultValueSql("nextval('processes_id_seq'::regclass)");

                entity.Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(100)
                    .HasColumnName("name");

                entity.Property(e => e.StartStepId).HasColumnName("start_step_id");

                entity.HasOne(d => d.StartStep)
                    .WithMany(p => p.RunnableProcesses)
                    .HasForeignKey(d => d.StartStepId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("processes_process_steps_id_fk");
            });

            modelBuilder.Entity<StartedProcess>(entity =>
            {
                entity.ToTable("started_processes");

                entity.Property(e => e.Id).HasColumnName("id");

                entity.Property(e => e.CreatedAt)
                    .HasColumnName("created_at")
                    .HasDefaultValueSql("timezone('utc'::text, now())");

                entity.Property(e => e.CurrentStepId).HasColumnName("current_step_id");

                entity.Property(e => e.ProcessId).HasColumnName("process_id");

                entity.HasOne(d => d.Process)
                    .WithMany(p => p.StartedProcesses)
                    .HasForeignKey(d => d.ProcessId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("started_processes_processes_id_fk");
            });

            modelBuilder.Entity<Unit>(entity =>
            {
                entity.ToTable("units");

                entity.HasIndex(e => e.Name, "units_name_uindex")
                    .IsUnique();

                entity.Property(e => e.Id).HasColumnName("id");

                entity.Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(100)
                    .HasColumnName("name");
            });

            OnModelCreatingPartial(modelBuilder);
        }

        partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
    }
}
